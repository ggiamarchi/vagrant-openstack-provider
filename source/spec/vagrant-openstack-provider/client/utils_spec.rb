require 'vagrant-openstack-provider/spec_helper'

include VagrantPlugins::Openstack

describe VagrantPlugins::Openstack::HttpUtils do

  let(:keystone) do
    double('keystone').tap do |keystone|
      keystone.stub(:authenticate).with(anything)
    end
  end

  let(:env) do
    Hash.new.tap do |env|
      env[:ui] = double('ui')
      env[:ui].stub(:warn).with(anything)
      env[:openstack_client] = double('openstack_client')
      env[:openstack_client].stub(:keystone) { keystone }
    end
  end

  class TestUtils
    include VagrantPlugins::Openstack::HttpUtils
    include VagrantPlugins::Openstack::Errors

    attr_writer :logger

    def target(env)
      authenticated(env) do
        env[:target].call
      end
    end
  end

  def error
    fail Errors::AuthenticationRequired
  end

  describe 'authenticated' do

    before :each do
      TestUtils.send(:public, *TestUtils.private_instance_methods)
      @utils = TestUtils.new
      @utils.logger = double.tap do |logger|
        logger.stub(:debug)
        logger.stub(:info)
      end
    end

    context 'with two authentication errors' do
      it 'should retry two times and success' do
        env[:target] = double.tap do |stub|
          nb_calls = 0
          stub.stub(:call) do
            nb_calls += 1
            fail Errors::AuthenticationRequired if nb_calls < 3
          end.and_return('object response')
        end
        env[:target].should_receive(:call).exactly(3).times

        response = @utils.target(env)

        expect(response).to eq('object response')
      end
    end

    context 'with three authentication errors' do
      it 'should retry two times and fail' do
        env[:target] = double.tap do |stub|
          stub.stub(:call) do
            fail Errors::AuthenticationRequired
          end
        end
        env[:target].should_receive(:call).exactly(3).times

        expect { @utils.target(env) }.to raise_error Errors::AuthenticationRequired
      end
    end
  end

  describe 'handle_response' do
    before :each do
      TestUtils.send(:public, *TestUtils.private_instance_methods)
      @utils = TestUtils.new
      @utils.logger = double.tap do |logger|
        logger.stub(:debug)
        logger.stub(:info)
      end
    end

    [200, 201, 202, 204].each do |code|
      context "response code is #{code}" do
        it 'should return the response' do
          mock_resp = double.tap do |mock|
            mock.stub(:code).and_return(code)
            mock.stub(:headers)
          end
          resp = @utils.handle_response(mock_resp)
          expect(resp.code).to eq(code)
        end
      end
    end

    context 'response code is 401' do
      it 'should return raise a AuthenticationRequired error' do
        mock_resp = double.tap do |mock|
          mock.stub(:code).and_return(401)
          mock.stub(:headers)
        end
        expect { @utils.handle_response(mock_resp) }.to raise_error Errors::AuthenticationRequired
      end
    end

    context 'response code is 400' do
      it 'should return raise a VagrantOpenstackError with bad request message' do
        mock_resp = double.tap do |mock|
          mock.stub(:code).and_return(400)
          mock.stub(:headers)
          mock.stub(:to_s).and_return('{ "badRequest": { "message": "Error... Bad request" } }')
        end
        begin
          @utils.handle_response(mock_resp)
          fail
        rescue Errors::VagrantOpenstackError => e
          expect(e.message).to eq('Error... Bad request')
        end
      end
    end

    context 'response code is 404' do
      it 'should raise a VagrantOpenstackError with conflict message' do
        mock_resp = double.tap do |mock|
          mock.stub(:code).and_return(404)
          mock.stub(:headers)
          mock.stub(:to_s).and_return('{ "itemNotFound": { "message": "Error... Not found" } }')
        end
        begin
          @utils.handle_response(mock_resp)
          fail
        rescue Errors::VagrantOpenstackError => e
          expect(e.message).to eq('Error... Not found')
        end
      end
    end

    context 'response code is 409' do
      it 'should return raise a VagrantOpenstackError with conflict message' do
        mock_resp = double.tap do |mock|
          mock.stub(:code).and_return(409)
          mock.stub(:headers)
          mock.stub(:to_s).and_return('{ "conflictingRequest": { "message": "Error... Conflict" } }')
        end
        begin
          @utils.handle_response(mock_resp)
          fail
        rescue Errors::VagrantOpenstackError => e
          expect(e.message).to eq('Error... Conflict')
        end
      end
    end

    context 'response code is 500' do
      it 'should return raise a VagrantOpenstackError error with error message' do
        mock_resp = double.tap do |mock|
          mock.stub(:code).and_return(500)
          mock.stub(:headers)
          mock.stub(:to_s).and_return('Internal server error')
        end
        begin
          @utils.handle_response(mock_resp)
          fail
        rescue Errors::VagrantOpenstackError => e
          expect(e.message).to eq('Internal server error')
        end
      end
    end
  end
end
