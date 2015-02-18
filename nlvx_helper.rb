require 'rest-client'
require 'json'

class NlvxHelper
   attr_accessor :user_id, :goseg_base_host, :apid_base_host, :tesla_base_host, :tesla_base_port, :goseg_base_url, :apid_base_url, :tesla_base_url, :dummy_email_addresses


  def set_user_id(i=0)
    if i == 0
    print "Enter user id: "
    id = gets.chomp
    @user_id = id
    else
      @user_id = i
    end

    puts "Using user id #{@user_id}"
    return id
  end

  def set_environment
    print "Select environment: (l)ocal, (s)taging, or (p)roduction > "
    environment = gets.chomp
    environment.downcase!
    puts environment
    case environment
      when "l"
        then puts "Using local development environment (localhost)"
        @goseg_base_host = "localhost"
        @apid_base_host = "localhost"
        @tesla_base_host = "localhost"
        @tesla_base_port = "3001"
        set_goseg_url
      set_apid_url
      when "s" then puts "Using staging"
         @goseg_base_host = "stdbcontact-002.sjc1.sendgrid.net"
         @apid_base_host = "stlb-001.sjc1.sendgrid.net"
         @tesla_base_host = "stteslago-001.sjc1.sendgrid.net"
         @tesla_base_port = "1701"
      when "p"
        then puts "Using production"
         @goseg_base_host = "dbcontact-002.sjc1.sendgrid.net"
         @apid_base_host = "lbapi-002.sjc1.sendgrid.net"
         @tesla_base_host = "teslago-001.sjc1.sendgrid.net"
         @tesla_base_port = "1701"
      else puts "Unknown environment"
    end

  end

   def print_vars
     puts "URLS: goseg #{@goseg_base_url} , apid #{@apid_base_url}"
     puts "#{@user_id}, #{@goseg_base_host}, #{@apid_base_host}"
   end

   def set_goseg_url
     @goseg_base_url = "http://#{@goseg_base_host}:9993/users/#{@user_id}"
   end

   def set_apid_url
     @apid_base_url = "http://#{@apid_base_host}:8082/api"
   end

   def set_tesla_url
     @tesla_base_url = "http://#{tesla_base_host}:1701"
   end

   def display_actions
     puts "\nChoose an action"
     puts "1) Create a new sender"
     puts "2) Create a bunch of random recipients in a list"
     puts "3) Create a new placeholder template"
     puts "4) Create a new campaign"
     puts "5) Create a new ASM group"
     puts "6) Delete all your recipients"
     puts "7) Delete all your lists"
     puts "8) Delete all your custom fields"
     puts "9) Delete all your segments"
     puts "q) Quit"
     # action = gets.chomp
     # return action
   end

   def run
    # display_actions
     command = ""
     display_actions
     while command != "q"
       input = gets.chomp
       case input
         when '1'
           then puts "Creating a new sender for user #{user_id}"
           create_sender_id("Test_Sender", "test123", "test@sendgrid.com")
         when '2'
           then puts "Creating random recipients and adding to a list"
         when '3'
           then puts "Create a new template is not implemented"
         when '4'
           then puts "Create a new campaign is not implemented"
         when '5'
           then puts "Create a new ASM group is not implemented"
         when '6'
           then puts "Deleting all recipients for user #{@user_id}"
           delete_all_recipients_batch
         when '7'
           then puts "Deleting all lists is not implemented"
         when '8'
           then puts "Deleting custom fields for user #{user_id}"
           delete_all_custom_fields
         when '9'
           then puts "Deleting all segments for user #{@user_id}"
           delete_all_segments_batch
         when 'q'
           then puts "Exiting..."
           break
         else
           puts "Unknown command: #{command}"
       end
       display_actions


     end
   end

   # get segments
   def get_all_segments
     url = "#{@base_url}/segments"
     return RestClient.get(url)
   end

   # get an array of all segment IDs
   def get_all_segment_ids
     allsegs = get_all_segments
     segs = JSON.parse(allsegs)
     # make an array of ids
     return segs['segments'].map {|k,v| k['id']}
   end

   # get all recipient IDs
  def get_all_recipient_ids
    url = "#{@goseg_base_url}/recipients/scroll"
    return RestClient.get(url)
  end


   def get_recipient_count
     url = "#{@goseg_base_url}/recipients/count"
     return RestClient.get(url)
   end

   def display_recipient_count
    response = JSON.parse(get_recipient_count)
     puts "you have #{response['count']} recipients"
   end

  def get_all_recipient_ids_as_array
    all_recips_raw = get_all_recipient_ids
    all_recips_hash = JSON.parse(all_recips_raw)
    return all_recips_hash['recipient_ids']
  end

   def add_all_recipient_ids_to_a_list
     suffix = [*('a'..'z')].sample(8).join
     list_response = create_list("new_test_list_#{suffix}")
     json_list_response = JSON.parse(list_response)
     list_id = json_list_response['id']
     recipient_list = get_all_recipient_ids_as_array
     payload = recipient_list.to_s
     url = "#{@base_url}/lists/#{list_id}/recipients_batch"
     RestClient.post(url,payload){|response, request, result| response }
   end
  # get custom fields
  def get_all_custom_fields()
    url = "#{@goseg_base_url}/custom_fields"
    puts url
    response = RestClient.get(url)
    return response
  end

   def list_senders
     url = "#{@apid_base_url}/api/nlvx/senderidentity/user/list.json?userid=#{@user_id}"
     response = RestClient.get(url)
   end

   # create a list
   def create_list(list_name)
     payload = {"name" => list_name}.to_json
     url = "#{@base_url}/lists"
     return RestClient.post(url,payload){|response, request, result| response }
   end

   def create_sender_id(name,nickname,email)
     #TODO: update with step to mark as verified
     url = "#{@apid_base_url}/nlvx/senderidentity/add.json?userid=#{@user_id}&nickname=#{nickname}&from_email=#{email}&from_name=#{name}"
     return RestClient.get(url)
   end

   def create_new_campaign
     # create sender
     sender_list = JSON.parse(list_senders)
     create_sender_id("NLVX_Tester","nlvx_test","team-tron@sendgrid.com") if sender_list['result'].empty?

     # create/populate a list
     # add campaign

     # add campaign contents
     # add campaign query
     # edit campaign
   end

   def generate_random_email_addresses(number_of_addresses)
     counter = 0
     address_list = Array.new
     puts "Generating #{number_of_addresses} addresses...."
     while counter < number_of_addresses
       suffix = [*('a'..'z')].sample(8).join
       add = "testuser_#{suffix}_#{counter}@sink.sendgrid.net"
       address_list.push(add)
       counter += 1
     end
     puts "Done"
     puts address_list.inspect
     return address_list
   end

   def create_email_list_for_batch_recipient_add(email_list)
     email_array = Array.new
     email_list.each do |email_address|
       addr_hash = {"email" => email_address}
       email_array.push(addr_hash)
     end
     return email_array
   end

   # add a batch of new recipients to All Contacts
   def add_batch_recipients(number_of_recipients=10)
     #dummy_email_addresses = ["test1@sink.sendgrid.net","test2@sink.sendgrid.net","test3@sink.sendgrid.net"]
     dummy_email_addresses = generate_random_email_addresses(number_of_recipients)
     email_array_batch_input = create_email_list_for_batch_recipient_add(dummy_email_addresses)
     payload = email_array_batch_input.to_json
     puts "adding recipients to db from #{payload}"
     url = "#{@goseg_base_url}/recipients_batch"
     res =  RestClient.post(url,payload){|response, request, result| response }
     return res
   end

  def delete_all_recipients_batch
    puts "Deleting all recipients for user #{@user_id}"
    re_array = get_all_recipient_ids_as_array
    # the id list has to be a string - passing in as a raw array results in a 400
    delete_recipients_batch(re_array)
  end

  # delete multiple recipients
  def delete_recipients_batch(recipient_array)
    url = "#{@goseg_base_url}/recipients"
    payload =  recipient_array.to_s
    puts "Deleting recipients from this list: #{payload}"
    foo = RestClient::Request.execute(:method => :delete, :url => url, :payload => payload){|response, request, result| response }
  end

   #delete a batch of segments
   def delete_segment_batch(segment_id_array)
     payload = segment_id_array.to_s
     url = "#{@base_url}/segments_batch"
     return RestClient::Request.execute(:method => :delete, :url => url, :payload => payload){|response, request, result| response }
   end

   def delete_all_segments_batch
     segment_id_array = get_all_segment_ids
     delete_segment_batch(segment_id_array.to_s)
   end

   # delete a custom field
   def delete_custom_field(custom_field_id)
     url = "#{@goseg_base_url}/custom_fields/#{custom_field_id}"
     puts url
     return RestClient.delete(url){|response, request, result| response }
   end

  #delete all custom fields
  def delete_all_custom_fields
    puts "Deleting custom fields for user #{@user_id}"
    fieldlist = get_all_custom_fields

    fields = JSON.parse(fieldlist)
    # make an array of ids
    field_ids = fields['custom_fields'].map {|k,v| k['id']}
    puts field_ids.length
    field_ids.each do |i|
      res = delete_custom_field(i)
    end
  end


  # to add
  # delete all recipients
  # delete all custom fields
  # delete all lists
  # delete all segments
  # create a new list with sample recipients
  # create a new sender
  # create a campaign
  # create a template
  # create an ASM group
  # add some phony stats for a campaign

end

n = NlvxHelper.new
n.set_user_id(76661)
n.set_environment
n.add_batch_recipients(100)
#n.run
# sleep(2)
# n.display_recipient_count
# sleep(2)
# n.delete_all_recipients_batch
# sleep(2)
# n.display_recipient_count
#n.delete_all_custom_fields