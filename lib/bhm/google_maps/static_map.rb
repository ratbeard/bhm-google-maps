module BHM
  module GoogleMaps
    class StaticMap
      URL = "http://maps.google.com/maps/api/staticmap?"
      COLOURS      = %w(red white green brown blue orange gray purple yellow black)
      LABELS       = ('A'..'Z')

      def initialize(locations, options = {})
        @locations = locations
        @params = {
          :sensor  => false,
          :size    => options[:size],
          :maptype => options.fetch(:type, "roadmap")
        }
        zoom = options.fetch(:zoom, @locations.length > 1 ? nil : 15)
        @params[:zoom] = zoom if zoom

        @cycle_colors = options[:cycle_colors]
        @cycle_labels = options[:cycle_labels]
      end

      def <<(address)
        @addresses << address
      end

      def to_url
        "#{URL}#{@params.to_param}#{marker_params}".html_safe
      end

      protected

      # Build the markers query param string from @locations
      def marker_params
        grouped_by_style = group_locations_by_style(@locations)
        grouped_by_style.each_with_object("") do |(style, locations), memo|
          memo << "&markers=#{style}#{locations}"
        end
      end

      # Group an array of locations together by shared style preferences.
      # Thats how the google api accepts them
      # size, color, label, icon
      def group_locations_by_style(locations)
        locations.each_with_object({}) do |location, store|
          styles = []
          if color = location.color
            styles << "color:#{color}"           
          end
          if size = location.size
            styles << "size:#{size}"             
          end
          if icon = location.icon
            styles << "icon:#{encode_url(icon)}"
          end
          if label = location.label
            styles << "label:#{label}"           
          end

          key = styles.join('|') 
          val = "|#{location.lat},#{location.lng}"
          (store[key] ||= "") << val
        end
      end


      def next_color
        @color_enum ||= COLOURS.to_enum
        @color_enum.next rescue @color_enum.rewind.next
      end
      
      def next_label
        @label_enum ||= LABELS.to_enum
        @label_enum.next rescue @label_enum.rewind.next
      end

      # old method:
      def build_marker_params
        return "markers=#{to_ll @addresses.first}" if @addresses.size == 1
        @addresses.each_with_index.map do |address, index|
          color = next_color
          label = next_label
          "markers=color:#{color}|label:#{label}|#{to_ll(address)}"
        end.join("&")
      end

      def to_ll(address)
        "#{address.lat},#{address.lng}"
      end

      def encode_url(url)
        URI.escape(url, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
      end

    end
  end
end
