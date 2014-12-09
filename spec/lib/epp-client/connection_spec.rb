require 'epp-client/connection'

RSpec.describe EPPClient::Connection do
  # TODO: use host class that is more like the one actually
  # used so that we don't have to stub so much
  subject do
    Class.new do
      include EPPClient::Connection
    end.new
  end

  describe "#send_frame" do
    let(:fake_socket){ instance_double(OpenSSL::SSL::SSLSocket).as_null_object }
    let(:fake_server){ instance_double(TCPSocket) }
    let(:server){ 'example.de' }
    let(:port){ 12345 }

    before do
      allow(OpenSSL::SSL::SSLSocket).to receive(:new).and_return(fake_socket)
      allow(TCPSocket).to receive(:new).and_return(fake_server)

      subject.stub(server: server,
                   port: port,
                   sent_frame_to_xml: nil,
                   get_frame: nil,
                   greeting_process: nil)

      subject.open_connection
    end

    context "when the document contains non-ascii characters" do
      let(:xml){ "<?xml version=\"1.0\" encoding=\"UTF-8\"?><epp xmlns=\"urn:ietf:params:xml:ns:epp-1.0\"><contact:name>Bättina Hülse</contact:name></epp>"
 }

      it "doesn't raise an exception" do
        expect{
          subject.send_frame(xml)
        }.not_to raise_exception
      end
    end
  end
end