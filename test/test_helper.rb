# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
Dir[File.expand_path('support/**/*.rb', __dir__)].sort.each { |f| require f }

require 'factory_bot'
require 'faker'
require 'net/http'
require 'io/console'
require 'byebug'
require 'minitest/autorun'
require 'webmock/minitest'
require 'mocha/minitest'

require_relative '../config/uffizzi'
require 'uffizzi'
require 'uffizzi/cli'
require 'uffizzi/config_file'
require 'uffizzi/shell'

include FixtureSupport
include UffizziStubSupport
include UffizziComposeStubSupport
include UffizziPreviewStubSupport

WebMock.disable_net_connect!

include FactoryBot::Syntax::Methods
FactoryBot.find_definitions

class Minitest::Test
  TEST_CONFIG_PATH = 'tmp/config_default.json'

  def before_setup
    super

    @mock_shell = MockShell.new
    Uffizzi::UI::Shell.stubs(:new).returns(@mock_shell)
    Uffizzi::ConfigFile.stubs(:config_path).returns(TEST_CONFIG_PATH)
  end

  def before_teardown
    super

    Uffizzi::ConfigFile.delete
  end

  def sign_in
    @cookie = '_uffizzi=test'
    login_body = json_fixture('files/uffizzi/uffizzi_login_success.json')
    @account_id = login_body[:user][:accounts].first[:id].to_s
    data = prepare_config_data
    data.each_pair { |key, value| Uffizzi::ConfigFile.write_option(key, value) }
  end

  def prepare_config_data
    {
      account_id: @account_id,
      server: Uffizzi.configuration.server,
      cookie: @cookie,
    }
  end

  def command_options(options)
    Thor::CoreExt::HashWithIndifferentAccess.new(options)
  end

  def sign_out
    Uffizzi::ConfigFile.unset_option(:cookie)
    Uffizzi::ConfigFile.unset_option(:account_id)
  end
end
