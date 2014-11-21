require 'vagrant-openstack-provider/spec_helper'

describe VagrantPlugins::Openstack::GlanceClient do

  let(:env) do
    Hash.new
  end

  let(:session) do
    VagrantPlugins::Openstack.session
  end

  before :each do
    session.token = '123456'
    session.project_id = 'a1b2c3'
    session.endpoints = { image: 'http://glance' }
    @glance_client = VagrantPlugins::Openstack.glance
  end

  describe 'get_all_images' do
    context 'with token and project_id acquainted' do
      context 'and api version is v2' do
        it 'returns all images with details' do
          stub_request(:get, 'http://glance/images')
          .with(
            headers:
              {
                'Accept' => 'application/json',
                'X-Auth-Token' => '123456'
              })
          .to_return(
            status: 200,
            body: '
            {
              "images": [
                { "id": "i1", "name": "image1", "visibility": "public",  "size": "1024", "min_ram": "1", "min_disk": "10" },
                { "id": "i2", "name": "image2", "visibility": "private", "size": "2048", "min_ram": "2", "min_disk": "20" }
              ]
            }')

          images = @glance_client.get_all_images(env)

          expect(images).to eq [Image.new('i1', 'image1', 'public',  '1024', '1', '10'),
                                Image.new('i2', 'image2', 'private', '2048', '2', '20')]
        end
      end

      context 'and api version is v1' do
        it 'returns all images with details' do
          stub_request(:get, 'http://glance/images')
          .with(
            headers:
              {
                'Accept' => 'application/json',
                'X-Auth-Token' => '123456'
              })
          .to_return(
            status: 200,
            body: '
            {
              "images": [
                { "id": "i1", "name": "image1", "is_public": true  },
                { "id": "i2", "name": "image2", "is_public": false }
              ]
            }')

          stub_request(:get, 'http://glance/images/detail')
          .with(
            headers:
              {
                'Accept' => 'application/json',
                'X-Auth-Token' => '123456'
              })
          .to_return(
            status: 200,
            body: '
            {
              "images": [
                { "id": "i1", "name": "image1", "is_public": true,  "size": "1024", "min_ram": "1", "min_disk": "10" },
                { "id": "i2", "name": "image2", "is_public": false, "size": "2048", "min_ram": "2", "min_disk": "20" }
              ]
            }')

          images = @glance_client.get_all_images(env)

          expect(images).to eq [Image.new('i1', 'image1', 'public',  '1024', '1', '10'),
                                Image.new('i2', 'image2', 'private', '2048', '2', '20')]
        end
      end
    end
  end

  describe 'get_api_version_list' do
    it 'returns version list' do
      stub_request(:get, 'http://glance/')
      .with(header: { 'Accept' => 'application/json' })
      .to_return(
        status: 200,
        body: '{
          "versions": [
            {
              "status": "...",
              "id": "v1.0",
              "links": [
                {
                  "href": "http://glance/v1.0",
                  "rel": "self"
                }
              ]
            },
            {
              "status": "CURRENT",
              "id": "v2.0",
              "links": [
                {
                  "href": "http://glance/v2.0",
                  "rel": "self"
                }
              ]
            }
          ]}')

      versions = @glance_client.get_api_version_list(env)

      expect(versions.size).to eq(2)
    end
  end
end
