module ApiAuth

  module Configuration # :nodoc:

    @@config = {
        header_prefix: 'ApiAuth',
        include_verb: false,
        included_headers: [],
        include_header_name: true
    }

    @@valid_config_keys = @@config.keys

# Configure through hash
    def configure(opts = {})
      opts.each { |k, v| @@config[k.to_sym] = v if @@valid_config_keys.include? k.to_sym }
      config[:included_headers].sort_by!{|word| word.downcase}
    end

    def config
      @@config
    end

  end
end
