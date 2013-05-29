module IRC
  class Channel
    PROPERTIES = [:channel, :socket]
    PROPERTIES.each { |prop|
      attr_accessor prop
    }
    def initialize(attributes = {})
      @channel = attributes[:channel]
      @socket = attributes[:socket]
    end

    def join
      @socket.writeData(Message.new(prefix: nil, command: 'JOIN', params: [channel]).toRaw, withTimeout: -1, tag: 0)

      @socket.readDataWithTimeout(-1, tag: 0);
    end
    def send(body)
      message = Message.new(prefix: nil, command: 'PRIVMSG', params: [@channel, body])
      @socket.writeData(message.toRaw, withTimeout: -1, tag: 0)
      @socket.readDataWithTimeout(-1, tag: 0);
    end
    def topic(topic)
      @socket.writeData(Message.new(prefix: nil, command: 'TOPIC', params: [@channel, topic]).toRaw, withTimeout: -1, tag: 0)
      @socket.readDataWithTimeout(-1, tag: 0);
    end
  end
  class Connection
    PROPERTIES = [:host, :port, :delegate, :name]
    PROPERTIES.each { |prop|
      attr_accessor prop
    }
    attr_reader :channels

    def initialize(attributes = {})
      attributes.each { |key, value|
        self.send("#{key}=", value) if PROPERTIES.member? key
      }

      @queue = Dispatch::Queue.new('com.ninjinkun.irc')
      @socket = GCDAsyncSocket.alloc.initWithDelegate(self, delegateQueue: @queue.dispatch_object)
      @channels = {}
    end

    def connect
      error_ptr = Pointer.new(:object)
      unless @socket.connectToHost(@host, onPort: @port, error: error_ptr)
        error = error_ptr[0]
        puts "Error when writing data: #{error}"
      end
      true
    end

    def join_channel(channel_name)
      socket = @socket
      channel = Channel.new(channel: channel_name, socket: socket)
      channel.join
      @channels[channel_name] = channel
    end

    def send_channel(channel_name, message)
      channel = @channels[channel_name]
      channel.send(message)
    end

    def pong
      @socket.writeData(Message.new(prefix: nil, command: 'PONG', params: []).toRaw, withTimeout: -1, tag: 0)
      @socket.readDataWithTimeout(-1, tag: 0);
    end

    # delegate methods
    def socket(socket, didConnectToHost: host, port: port)

      @socket.writeData(Message.new(prefix: nil, command: 'NICK', params: [@name]).toRaw, withTimeout: -1, tag: 10)
      @socket.writeData(Message.new(prefix: nil, command: 'USER', params: [@name, '0', '*', @name]).toRaw, withTimeout: -1, tag: 11)
      @socket.readDataWithTimeout(-1, tag: 0);
      @buffer ||= ""
    end

    def socket(socket, didReadData: data, withTag: tag)
      @buffer += data.nsstring
      @socket.readDataWithTimeout(-1, tag: 0);
      messages = @buffer.split(/\r\n/).map { |line| IRC::Message.parse(line) }
      if messages.find { |message| message.command == 'PING' }
        pong
      end

      if delegate.respond_to?('irc:didReceiveMessages:')
        delegate.irc(self, didReceiveMessages: messages) 
      end
    end

    def socketDidDisconnect(socket, withError: error)
        puts "Error when on connect: #{error}"
    end
    
  end
end
