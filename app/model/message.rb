# Inspired by
# https://gist.github.com/hakobe/5628019
# https://github.com/Nerdmaster/ruby-irc-yail/blob/develop/lib/net/yail/message_parser.rb

module IRC
  class Message
    PROPERTIES = [:nick, :user, :host, :prefix, :command, :params, :servername]
    PROPERTIES.each { |prop|
      attr_accessor prop
    }

    USER        = /\S+?/

    NICK        = /[\w\d\\|`'^{}\]\[-]+?/
    HOST        = /\S+?/
    SERVERNAME  = /\S+?/

    PREFIX      = /((#{NICK})!(#{USER})@(#{HOST})|#{SERVERNAME})/
    COMMAND     = /(\w+|\d{3})/
    TRAILING    = /\:\S*?/
    MIDDLE      = /(?: +([^ :]\S*))/

    MESSAGE     = /^(?::#{PREFIX} +)?#{COMMAND}(.*)$/

    def initialize(attributes = {})
      attributes.each { |key, value|
        self.send("#{key}=", value) if PROPERTIES.member? key
      }
    end

    def Message.parse(line)
      params = []
      nick, user, host, servername, command, prefix = nil
      if line =~ MESSAGE
        matches = Regexp.last_match

        prefix = matches[1]

        if (matches[2])
          nick = matches[2]
          user = matches[3]
          host = matches[4]
        else
          servername = matches[1]
        end

        command = matches[5]

        arglist = matches[6].sub(/^ +/, '')
        arglist.sub!(/^:/, ' :')
        (middle_args, trailing_arg) = (arglist || '').split(/ +:/, 2)
        params.push((middle_args || '').split(/ +/), trailing_arg)
        params.compact!
        params.flatten!
      end
      
      Message.new( prefix: prefix, command: command, params: params, host: host, user: user, nick: nick, servername: servername)
    end

    def toRaw
      result = ''

      if self.prefix
        result += ':' + this.prefix + ' '
      end
      
      result += self.command + ' '
      
      params = (self.params || []).dup
      trailing = params[ params.length - 1];
      if trailing && (trailing.match(/\s/) || trailing === '')
        params[ params.length - 1]  = ':' + trailing
      end
      
      result += params.join(' ')
      result += "\r\n";
      result.nsdata
    end
  end
end
