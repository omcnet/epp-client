require 'nokogiri'

def readXML(file)
	File.read(File.expand_path(file))
end

def parseXML(xml)
	Nokogiri::XML::Document.parse(xml,nil,nil,256)
end

def toXML(xml)
	xml.to_xml(:save_with=>Nokogiri::XML::Node::SaveOptions::AS_XML).gsub(/\sxsi:schemaLocation=\"[^\"]*\"|\sxmlns:xsi=\"[^\"]+\"|\sstandalone=\"no\"/, '').strip
end

def readCleanXML(path)
	toXML(parseXML(readXML(path)))
end
