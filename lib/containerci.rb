require 'rake'
require 'rake/tasklib'
require "containerci/version"

module ContainerCI
  #
  # Exports a github project into a container--set up so that CI systems
  # can push this and pull the latest source.
  #
  class ExportGithubProjectIntoContainer < ::Rake::TaskLib
    def initialize(dsl: ::Rake::Task)
      @dsl = dsl
      define
    end

    def os
      os = `uname -s`.chomp
      os.downcase
    end

    def docker_machine_url
      'https://github.com/docker/machine/releases/download/v0.3.0/' \
      "docker-machine_#{os}-amd64"
    end

    def current_version
      `docker images | grep -v latest | grep ^#{USER}/#{PROJECT_NAME} | \
     awk '{print $2}' | head -1`
    end

    def next_version
      @next_version ||= `sh -c 'TZ=UTC date +%Y-%m-%d-%H%M'`.chomp
    end

    def define
      # XXX: Document circleci.yml
      @dsl.define_task(:update_github_project) do
        puts "pulling #{GITHUB_PROJECT}..."
        if Dir.exist? GITHUB_PROJECT
          sh "cd #{GITHUB_PROJECT} && git pull origin tests_passed"
        else
          sh 'git clone https://$GITHUB_OAUTH:x-oauth-basic@' \
             "github.com/#{USER}/#{GITHUB_PROJECT}.git"
        end
        sh "cd #{GITHUB_PROJECT} && git checkout tests_passed"
        puts 'done'
      end

      @dsl.define_task(:restore_cache) do
        puts 'Restoring from docker cache...'
        sh "if [ -e ~/docker/#{PROJECT_NAME}.tar ]; " \
           'then ' \
           '  echo "restoring from cache"; ' \
           "  docker load -i ~/docker/#{PROJECT_NAME}.tar;" \
           'fi; '
        puts 'done'
      end

      # XXX: Why do we have to pull all images here, just to figure out what
      # the latest version is?  Wish we could just pull latest.

      @dsl.define_task(:raw_docker_pull) do
        puts 'Pulling from dockerhub...'
        sh 'false; ' \
           'until [ $? -eq 0 ]; do ' \
           "docker pull #{USER}/#{PROJECT_NAME}:latest < /dev/null; done"
        puts 'done'
      end

      @dsl.define_task(:save_new_cache) do
        sh "mkdir -p ~/docker; docker save #{USER}/#{PROJECT_NAME}:latest > " \
           "  ~/docker/#{PROJECT_NAME}.tar"
      end

      @dsl.define_task(:get_docker_machine) do
        sh 'if [ ! -d ~/docker-machine ]; ' \
           'then ' \
           '  mkdir -p ~/docker-machine; ' \
           'fi'
        sh 'if [ ! -f ~/docker-machine/docker-machine ]; ' \
           'then ' \
           "  curl -L #{docker_machine_url} > " \
           '      ~/docker-machine/docker-machine; ' \
           'fi'
        sh 'if [ ! -x ~/docker-machine/docker-machine ]; ' \
           'then ' \
           '  chmod +x ~/docker-machine/docker-machine; ' \
           'fi'
      end

      @dsl.define_task(docker_pull:
                         [:restore_cache, :raw_docker_pull, :save_new_cache])

      @dsl.define_task(dependencies:
                         [:update_github_project, :docker_pull, :get_docker_machine])

      @dsl.define_task(:print_next_version) do
        puts "next version is #{next_version}"
      end

      @dsl.define_task(:docker_build_next_version) do
        sh "docker build -t #{USER}/#{PROJECT_NAME}:#{next_version} ."
      end

      @dsl.define_task(:docker_tag) do
        sh "docker tag -f #{USER}/#{PROJECT_NAME}:#{next_version} " \
           "#{USER}/#{PROJECT_NAME}:latest"
      end

      @dsl.define_task(build:
                         [:print_next_version,
                          :docker_build_next_version,
                          :docker_tag])

      @dsl.define_task(test:
                         [:build,
                          # :start_container, :verify_listening_on_port, :stop_container
                         ])

      @dsl.define_task(:docker_push) do
        sh "docker push #{USER}/#{PROJECT_NAME}"
        sh "docker push #{USER}/#{PROJECT_NAME}:#{current_version}"
      end

      @dsl.define_task(:manual_deploy) do
        sh "in-sinatra-vld-prod docker pull #{USER}/#{PROJECT_NAME}:latest"
        sh 'in-sinatra-vld-prod docker ps'
        sh 'in-sinatra-vld-prod docker kill `in-sinatra-vld-prod docker ps -l -q`'
        sh 'in-sinatra-vld-prod docker run -d -P -p 0.0.0.0:4567:4567 ' \
           "-v /root/private:/root/private #{USER}/#{PROJECT_NAME}"
        sh 'in-sinatra-vld-prod docker ' \
           'exec -it `in-sinatra-vld-prod docker ps -l -q` /bin/dropbox ' \
           'status'
        puts "After connected, hit Control-C and run 'rake wait_for_dropbox'"
        sh 'in-sinatra-vld-prod docker exec -it ' \
           '`in-sinatra-vld-prod docker ps -l -q` ' \
           'tail -f /var/log/dropbox/dropbox.log'
      end

      @dsl.define_task(after_test_success:
                         [:docker_push,
                          #:deploy_to_prod
                         ])
    end
    # XXX: As configured in CircleCI, this runs regardless of whether test passed

  end
end
