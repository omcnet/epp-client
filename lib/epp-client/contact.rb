module EPPClient
  module Contact
    EPPClient::Poll::PARSERS['contact:infData'] = :contact_info_process

		CONTACT_NS = 'contact'

		def contact_check_xml(contacts)
			command do |xml|
				xml.check do
					xml.check do
						xml.parent.namespace = xml.parent.add_namespace_definition(CONTACT_NS, EPPClient::SCHEMAS_URL[CONTACT_NS])
						contacts[:ids].each do |contact|
							xml[CONTACT_NS].id contact
						end
						if contacts.key?(:authInfo)
							xml[CONTACT_NS].authInfo do
								xml[CONTACT_NS].pw(contacts[:authInfo])
							end
						end
					end
				end
			end
		end

    # Check the availability of contacts
    #
    # takes list of contacts as arguments
    #
    # returns an array of hashes containing three fields :
    # [<tt>:id</tt>] the contact id
    # [<tt>:avail</tt>] wether the contact id can be provisionned.
    # [<tt>:reason</tt>]
    #   the server-specific text to help explain why the object cannot be
    #   provisioned.
    #
    def contact_check(*contacts)
      contacts.flatten!

      response = send_request(contact_check_xml(*contacts))
      get_result(:xml => response, :callback => :contact_check_process)
    end

    def contact_check_process(xml)
			ret = xml.xpath('epp:resData/contact:chkData/contact:cd', EPPClient::SCHEMAS_URL).map do |dom|
				res = {
					:name => dom.xpath('contact:id', EPPClient::SCHEMAS_URL).text,
					:avail => dom.xpath('contact:id', EPPClient::SCHEMAS_URL).attr('avail').value == '1',
				}

				unless (reason = dom.xpath('contact:reason', EPPClient::SCHEMAS_URL).text).empty?
				  res[:reason] = reason
				end
				res
			end
			ret
		end

		def contact_info_xml(contact)
			command do |xml|
				xml.info do
					xml.info do
						xml.parent.namespace = xml.parent.add_namespace_definition(CONTACT_NS, EPPClient::SCHEMAS_URL[CONTACT_NS])
						xml[CONTACT_NS].id contact[:id]
					end
					if contact.key?(:authInfo)
						xml[CONTACT_NS].authInfo do
							xml[CONTACT_NS].pw(contact[:authInfo])
						end
					end
				end
			end
		end

    # Returns the informations about a contact
    #
    # Takes either a unique argument, either
    # a string, representing the contact id
    # or a hash with the following keys :
    # [<tt>:id</tt>] the contact id, and optionnaly
    # [<tt>:authInfo</tt>] an optional authentication information.
    #
    # Returned is a hash mapping as closely as possible the result expected
    # from the command as per Section 3.1.2 of RFC 5733 :
    # [<tt>:id</tt>]
    #   the server-unique identifier of the contact object. Most of the time,
    #   the nic handle.
    # [<tt>:roid</tt>]
    #   the Repository Object IDentifier assigned to the contact object when
    #   the object was created.
    # [<tt>:status</tt>] the status of the contact object.
    # [<tt>:postalInfo</tt>]
    #   a hash containing one or two keys, +loc+ and +int+ representing the
    #   localized and internationalized version of the postal address
    #   information. The value is a hash with the following keys :
    #   [<tt>:name</tt>]
    #     the name of the individual or role represented by the contact.
    #   [<tt>:org</tt>]
    #     the name of the organization with which the contact is affiliated.
    #   [<tt>:addr</tt>]
    #     a hash with the following keys :
    #     [<tt>:street</tt>]
    #       an array that contains the contact's street address.
    #     [<tt>:city</tt>] the contact's city.
    #     [<tt>:sp</tt>] the contact's state or province.
    #     [<tt>:pc</tt>] the contact's postal code.
    #     [<tt>:cc</tt>] the contact's country code.
    # [<tt>:voice</tt>] the contact's optional voice telephone number.
    # [<tt>:fax</tt>] the contact's optional facsimile telephone number.
    # [<tt>:email</tt>] the contact's email address.
    # [<tt>:clID</tt>] the identifier of the sponsoring client.
    # [<tt>:crID</tt>]
    #   the identifier of the client that created the contact object.
    # [<tt>:crDate</tt>] the date and time of contact-object creation.
    # [<tt>:upID</tt>]
    #   the optional identifier of the client that last updated the contact
    #   object.
    # [<tt>:upDate</tt>]
    #   the optional date and time of the most recent contact-object
    #   modification.
    # [<tt>:trDate</tt>]
    #   the optional date and time of the most recent successful contact-object
    #   transfer.
    # [<tt>:authInfo</tt>]
    #   authorization information associated with the contact object.
    # [<tt>:disclose</tt>]
    #   an optional array that identifies elements that require exceptional
    #   server-operator handling to allow or restrict disclosure to third
    #   parties. See
    #   section 2.9[http://tools.ietf.org/html/rfc5733#section-2.9] of RFC 5733
    #   for details.
    def contact_info(args)
      if String === args
	args = {:id => args}
      end
      response = send_request(contact_info_xml(args))

      get_result(:xml => response, :callback => :contact_info_process)
    end

    def contact_info_process(xml) #:nodoc:
      contact = xml.xpath('epp:resData/contact:infData', EPPClient::SCHEMAS_URL)
      ret = {
	:id => contact.xpath('contact:id', EPPClient::SCHEMAS_URL).text,
	:roid => contact.xpath('contact:roid', EPPClient::SCHEMAS_URL).text,
      }
      if (status = contact.xpath('contact:status', EPPClient::SCHEMAS_URL)).size > 0
	ret[:status] = status.map {|s| s.attr('s')}
      end

      if (postalInfo = contact.xpath('contact:postalInfo', EPPClient::SCHEMAS_URL)).size > 0
	ret[:postalInfo] = postalInfo.inject({}) do |acc, p|
	  type = p.attr('type').to_sym
	  acc[type] = { :name => p.xpath('contact:name', EPPClient::SCHEMAS_URL).text, :addr => {} }
	  if (org = p.xpath('contact:org', EPPClient::SCHEMAS_URL)).size > 0
	    acc[type][:org] = org.text
	  end
	  addr = p.xpath('contact:addr', EPPClient::SCHEMAS_URL)

	  acc[type][:addr][:street] = addr.xpath('contact:street', EPPClient::SCHEMAS_URL).map {|s| s.text}
	  %w(city cc).each do |val|
	    acc[type][:addr][val.to_sym] = addr.xpath("contact:#{val}", EPPClient::SCHEMAS_URL).text
	  end
	  %w(sp pc).each do |val|
	    if (r = addr.xpath("contact:#{val}", EPPClient::SCHEMAS_URL)).size > 0
	      acc[type][:addr][val.to_sym] = r.text
	    end
	  end

	  acc
	end
      end

      %w(voice fax email clID crID upID).each do |val|
	if (value = contact.xpath("contact:#{val}", EPPClient::SCHEMAS_URL)).size > 0
	  ret[val.to_sym] = value.text
	end
      end
      %w(crDate upDate trDate).each do |val|
	if (date = contact.xpath("contact:#{val}", EPPClient::SCHEMAS_URL)).size > 0
	  ret[val.to_sym] = DateTime.parse(date.text)
	end
      end
      if (authInfo = contact.xpath('contact:authInfo', EPPClient::SCHEMAS_URL)).size > 0
	ret[:authInfo] = authInfo.xpath('contact:pw', EPPClient::SCHEMAS_URL).text
      end
      if (disclose = contact.xpath('contact:disclose', EPPClient::SCHEMAS_URL)).size > 0
	ret[:disclose] = { :flag => disclose.attr('flag').value == '1', :elements => [] }
	disclose.children.each do |c|
	  r = { :name => c.name }
	  unless (type = c.attr('type').value).nil?
	    r[:type] == type
	  end
	  ret[:disclose][:elements] << r
	end
      end
      ret
    end

		def contact_create_xml(contact) #:nodoc:
			command do |xml|
				xml.create do
					xml.create do
						xml.parent.namespace = xml.parent.add_namespace_definition(CONTACT_NS, EPPClient::SCHEMAS_URL[CONTACT_NS])
						xml[CONTACT_NS].id contact.key?(:id) ? contact[:id] : 'dummy'
						contact[:postalInfo].each do |type,infos|
							xml[CONTACT_NS].postalInfo :type => type do
								xml[CONTACT_NS].name infos[:name]
								xml[CONTACT_NS].org infos[:org] if infos.key?(:org)
								xml[CONTACT_NS].addr do
									infos[:addr][:street].each do |street|
										xml[CONTACT_NS].street street
									end
									xml[CONTACT_NS].city infos[:addr][:city]
									[:sp, :pc].each do |val|
										xml[CONTACT_NS].__send__(val, infos[:addr][val]) if infos[:addr].key?(val)
									end
									xml[CONTACT_NS].cc infos[:addr][:cc]
								end
							end
						end
						[:voice, :fax].each do |val|
							xml[CONTACT_NS].__send__(val, contact[val]) if contact.key?(val)
						end
						xml[CONTACT_NS].email contact[:email]
						xml[CONTACT_NS].authInfo do
							xml[CONTACT_NS].pw contact[:authInfo]
						end
						if contact.key?(:disclose)
							xml[CONTACT_NS].disclose do
								contact[:disclose].each do |disc|
									if disc.key?(:type)
										xml[CONTACT_NS].__send__(disc[:name], :type => disc[:type])
									else
										xml[CONTACT_NS].__send__(disc[:name])
									end
								end
							end
						end
					end
				end
			end
		end

    # Creates a contact
    #
    # Takes a hash as an argument containing the following keys :
    #
    # [<tt>:id</tt>]
    #   the server-unique identifier of the contact object. Most of the time,
    #   the nic handle.
    # [<tt>:postalInfo</tt>]
    #   a hash containing one or two keys, +loc+ and +int+ representing the
    #   localized and internationalized version of the postal address
    #   information. The value is a hash with the following keys :
    #   [<tt>:name</tt>]
    #     the name of the individual or role represented by the contact.
    #   [<tt>:org</tt>]
    #     the name of the organization with which the contact is affiliated.
    #   [<tt>:addr</tt>]
    #     a hash with the following keys :
    #     [<tt>:street</tt>]
    #       an array that contains the contact's street address.
    #     [<tt>:city</tt>] the contact's city.
    #     [<tt>:sp</tt>] the contact's state or province.
    #     [<tt>:pc</tt>] the contact's postal code.
    #     [<tt>:cc</tt>] the contact's country code.
    # [<tt>:voice</tt>] the contact's optional voice telephone number.
    # [<tt>:fax</tt>] the contact's optional facsimile telephone number.
    # [<tt>:email</tt>] the contact's email address.
    # [<tt>:authInfo</tt>]
    #   authorization information associated with the contact object.
    # [<tt>:disclose</tt>]
    #   an optional array that identifies elements that require exceptional
    #   server-operator handling to allow or restrict disclosure to third
    #   parties. See
    #   section 2.9[http://tools.ietf.org/html/rfc5733#section-2.9] of RFC 5733
    #   for details.
    #
    # Returns a hash with the following keys :
    #
    # [<tt>:id</tt>] the nic handle.
    # [<tt>:crDate</tt>] the date and time of contact-object creation.
    def contact_create(contact)
      response = send_request(contact_create_xml(contact))

      get_result(:xml => response, :callback => :contact_create_process)
    end

    def contact_create_process(xml) #:nodoc:
      contact = xml.xpath('epp:resData/contact:creData', EPPClient::SCHEMAS_URL)
      {
	:id => contact.xpath('contact:id', EPPClient::SCHEMAS_URL).text,
	:crDate => DateTime.parse(contact.xpath('contact:crDate', EPPClient::SCHEMAS_URL).text),
      }
    end

    def contact_delete_xml(contact) #:nodoc:
			command do |xml|
				xml.delete do
					xml.delete do
						xml.parent.namespace = xml.parent.add_namespace_definition(CONTACT_NS, EPPClient::SCHEMAS_URL[CONTACT_NS])
						xml[CONTACT_NS].id(contact)
					end
				end
			end
		end

    # Deletes a contact
    #
    # Takes a single nic handle for argument.
    #
    # Returns true on success, or raises an exception.
    def contact_delete(contact)
      response = send_request(contact_delete_xml(contact))

      get_result(response)
    end

    def contact_update_xml(args) #:nodoc:
			command do |xml|
				xml.update do
					xml.update do
						xml.parent.namespace = xml.parent.add_namespace_definition(CONTACT_NS, EPPClient::SCHEMAS_URL[CONTACT_NS])
						xml[CONTACT_NS].id args[:id]
						if args.key?(:add) && args[:add].key?(:status)
							xml[CONTACT_NS].add do
								args[:add][:status].each do |s|
									xml[CONTACT_NS].status :s => s
								end
							end
						end
						if args.key?(:rem) && args[:rem].key?(:status)
							xml[CONTACT_NS].rem do
								args[:rem][:status].each do |s|
									xml[CONTACT_NS].status :s => s
								end
							end
						end
						if args.key?(:chg)
							contact = args[:chg]
							xml[CONTACT_NS].chg do
								if contact.key?(:postalInfo)
									contact[:postalInfo].each do |type,infos|
										xml[CONTACT_NS].postalInfo :type => type do
											xml[CONTACT_NS].name(infos[:name]) if infos.key?(:name)
											xml[CONTACT_NS].org(infos[:org]) if infos.key?(:org)
											if infos.key?(:addr)
												xml[CONTACT_NS].addr do
													infos[:addr][:street].each do |street|
														xml[CONTACT_NS].street(street)
													end
													xml[CONTACT_NS].city(infos[:addr][:city])
													[:sp, :pc].each do |val|
														xml[CONTACT_NS].__send__(val, infos[:addr][val]) if infos[:addr].key?(val)
													end
													xml[CONTACT_NS].cc(infos[:addr][:cc])
												end
											end
										end
									end
								end
								[:voice, :fax, :email].each do |val|
									xml[CONTACT_NS].__send__(val, contact[val]) if contact.key?(val)
								end
								if contact.key?(:authInfo)
									xml[CONTACT_NS].authInfo do
										xml[CONTACT_NS].pw(contact[:authInfo])
									end
								end
								if contact.key?(:disclose)
									xml[CONTACT_NS].disclose(:flag=>contact[:disclose][:flag]) do
										contact[:disclose][:elements].each do |disc|
											if disc.is_a?(Hash)
												xml[CONTACT_NS].__send__(disc[:name], :type => disc[:type])
											else
												xml[CONTACT_NS].__send__(disc)
											end
										end
									end
								end
							end
						end
					end
				end
			end
		end

    # Updates a contact
    #
    # Takes a hash with the id, and at least one of the following keys :
    # [<tt>:id</tt>]
    #   the server-unique identifier of the contact object to be updated.
    # [<tt>:add</tt>/<tt>:rem</tt>]
    #   adds or removes the following data from the contact object :
    #   [<tt>:status</tt>] an array of status to add to/remove from the object.
    # [<tt>:chg</tt>]
    #   changes the datas of the contact object, takes the same arguments as
    #   the creation of the contact, except the id, with the small change that
    #   each first level key is now optional. (Meaning that you don't have to
    #   supply a <tt>:postalInfo</tt> if you don't need to, but if you do, all
    #   it's mandatory fields are mandatory.)
    #
    # Returns true on success, or raises an exception.
    def contact_update(args)
      response = send_request(contact_update_xml(args))

      get_result(response)
    end
  end
end
