require 'spec_helper'

describe 'Contacts' do
  let(:tester){
    EPPClient::Base.new(
			:clTRID => 'fix',
			:password => "test",
			:client_id => 0,
      :server => 'example.com'
    )
	}
  context 'check' do
    it 'IETF sample' do
      xml_c = readCleanXML('spec/xml/contact_check_c.xml')
      xml_s = readCleanXML('spec/xml/contact_check_s.xml')
      allow_message_expectations_on_nil
      expect(nil).to receive(:write).with([xml_c.length+4].pack('N')+xml_c).once
			expect(nil).to receive(:read).with(4).once {[xml_s.length+4].pack('N')}
			expect(nil).to receive(:read).with(xml_s.length).once {xml_s}
      expect(tester.contact_check ['sh8013','sah8013','8013sah']).to eq(
        [{:name=>"sh8013", :avail=>true},
          {:name=>"sah8013", :avail=>false, :reason=>"In use"},
          {:name=>"8013sah", :avail=>true}])
    end
  end
  context 'info' do
    it 'IETF sample' do
      xml_c = readCleanXML('spec/xml/contact_info_c.xml')
      xml_s = readCleanXML('spec/xml/contact_info_s.xml')
      allow_message_expectations_on_nil
      expect(nil).to receive(:write).with([xml_c.length+4].pack('N')+xml_c).once
      expect(nil).to receive(:read).with(4).once {[xml_s.length+4].pack('N')}
      expect(nil).to receive(:read).with(xml_s.length).once {xml_s}
      expect(tester.contact_info :id => 'sh8013', :authInfo => '2fooBAR').to eq(
        {:id=>"sh8013", :roid=>"SH8013-REP", :status=>["linked", "clientDeleteProhibited"],
          :postalInfo=>{:int=>{:name=>"John Doe",
            :addr=>{:street=>["123 Example Dr.", "Suite 100"],
              :city=>"Dulles", :cc=>"US", :sp=>"VA", :pc=>"20166-6503"}, :org=>"Example Inc."}},
          #to grant compatibility create a separeted field :voice_x => "1234",
          :voice=>"+1.7035555555", :fax=>"+1.7035555556", :email=>"jdoe@example.com",
          :clID=>"ClientY", :crID=>"ClientX", :upID=>"ClientX",
          :crDate=>DateTime.parse("1999-04-03T22:00:00Z"),
          :upDate=>DateTime.parse("1999-12-03T09:00:00Z"),
          :trDate=>DateTime.parse("2000-04-08T09:00:00Z"),
          :authInfo=>"2fooBAR",
          :disclose=>{:flag=>false, :elements=>[{:name=>"voice"}, {:name=>"email"}]}})
    end
  end
end
