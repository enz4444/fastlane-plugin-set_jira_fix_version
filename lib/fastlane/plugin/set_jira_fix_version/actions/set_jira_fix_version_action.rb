module Fastlane
  module Actions
    class SetJiraFixVersionAction < Action
      def self.run(params)
        Actions.verify_gem!('jira-ruby')
        require 'jira-ruby'

        project_id   = params[:project_key]
        version_name = params[:version_name]
        issue_ids    = self.issue_ids_from_param(params)

        client = JIRA::Client.new(
          username:     params[:username],
          password:     params[:password],
          site:         params[:url],
          context_path: '',
          auth_type:    :basic

        )

        self.save_version(client, version_name, project_id, issue_ids)
      end

      def self.issue_ids_from_param(params)
        issue_ids = params[:issue_ids]

        if issue_ids.nil?
          issue_ids = Actions.lane_context[SharedValues::FL_JIRA_ISSUE_IDS]
        end

        if issue_ids.kind_of?(Array) == false || issue_ids.empty?
          UI.user_error!("No issue ids or keys were supplied or the value is not an array.")
          return
        end

        UI.message("Issues: #{issue_ids}")
        return issue_ids
      end

      def self.save_version(client, version_name, project_key, issue_ids)
        UI.message("Update fix version to #{version_name} for below tickets:\n#{issue_ids}")
        # update issues with fix version
        issue_ids.each do |issue_id|
          begin
            issue = client.Issue.find(issue_id)
          rescue
            UI.error("JIRA issue with #{issue_id} is not found or specified user don't have permissions to see it. It won't be updated!")
          end
          if issue.fixVersions.empty?
            add_new_version_parameters = { 'update' => { 'fixVersions' => [{ 'add' => { 'name' => version_name } }] } }
            issue.save(add_new_version_parameters)
            UI.message("#{issue_id} is updated with fix version #{version_name}.")
          else
            UI.message("#{issue_id} already has a fix version, will skip update.")
        end
      end

      #####################################################
      # @!group Documentation
      #####################################################

      def self.description
        "Adds fix version to specified JIRA issues. Creates version if needed"
      end

      def self.details
        [
          "This action allows to easily add fix version to specified JIRA issues. It supports basic and cookie authorization.",
          "If JIRA account password won't be specified in parameters (recommended) it will ask it at first launch and save in a macOS keychain.",
          "If JIRA version with specified name is not created, this action will create it. The action can take issue IDs from lane context",
          "(FL_JIRA_ISSUE_IDS) and many other JIRA related parameters from environment variables."
        ].join("\n")
      end

      def self.available_options
        [
          FastlaneCore::ConfigItem.new(key: :url,
                                      env_name: "FL_JIRA_SITE",
                                      description: "URL for JIRA instance",
                                       verify_block: proc do |value|
                                         UI.user_error!("No url for JIRA given, pass using `url: 'url'`") if value.to_s.length == 0
                                       end),
          FastlaneCore::ConfigItem.new(key: :username,
                                       env_name: "FL_JIRA_USERNAME",
                                       optional: true,
                                       description: "Username for JIRA"),
          FastlaneCore::ConfigItem.new(key: :password,
                                       env_name: "FL_JIRA_PASSWORD",
                                       description: "Password for JIRA",
                                       optional: true,
                                       sensitive: true),
          FastlaneCore::ConfigItem.new(key: :auth_type,
                                       description: "Authorization type to use. Currently supported: :basic or :cookie",
                                       default_value: :basic),
          FastlaneCore::ConfigItem.new(key: :use_cookies,
                                       description: "Whether JIRA client should use cookies",
                                       default_value: false),
          FastlaneCore::ConfigItem.new(key: :issue_ids,
                                       description: "Issue IDs or keys for JIRA, i.e. [\"IOS-123\", \"IOS-123\"]",
                                       optional: true,
                                       is_string: false),
          FastlaneCore::ConfigItem.new(key: :version_name,
                                       env_name: "FL_JIRA_VERSION_NAME",
                                       description: "Version name that will be set as fix version to specified issues.\nIf version does not exist, it will be created",
                                       is_string: true,
                                       optional: true),
          FastlaneCore::ConfigItem.new(key: :project_key,
                                       env_name: "FL_JIRA_PROJECT_ID",
                                       description: "Project ID or key where version will be created if needed",
                                       is_string: true,
                                       optional: true)
        ]
      end

      def self.authors
        ["yuriy-tolstoguzov", "vadimux"]
      end

      def self.example_code
        [
          'set_jira_fix_version(
            url: "https://jira.yourdomain.com",
            username: "Your username",
            issue_ids: ["IOS-1000", "IOS-1001"],
            version_name: "1.0.0 (123)",
            project_key: "IOS"
          )'
        ]
      end

      def self.category
        :misc
      end

      def self.is_supported?(platform)
        true
      end
    end
  end
end
