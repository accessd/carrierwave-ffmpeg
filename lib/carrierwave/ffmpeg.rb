require 'carrierwave'
require 'streamio-ffmpeg'

module CarrierWave
  module FFmpeg
    extend ActiveSupport::Concern

    DEFAULT_SEEK = 10

    module ClassMethods
      def encode(format, opts = {})
        process encode: [ format, opts ]
      end

      def movie path
        ::FFMPEG::Movie.new path
      end
    end

    def encode(format, opts = {})
      tmp_path = File.join File.dirname(current_path), "tmp_file.#{format}"
      file = movie current_path
      file.transcode tmp_path, options(format, file, opts), transcoder_options
      File.rename tmp_path, current_path
    end

    def codec(format)
      if format == :jpg
        {}
      else
        raise CarrierWave::ProcessingError, 'Unsupported format'
      end
    end

    def custom_options(format, file, opts)
      return unless format == :jpg
      frame_num = if opts[:frame_num].present?
                    opts[:frame_num]
                  else
                    seek = opts[:seek] || DEFAULT_SEEK
                    (file.duration.to_f * file.frame_rate.to_f * seek.to_f / 100).to_i
                  end
      { custom: ['-vf', "select=gte(n\\,#{frame_num})", '-vframes', 1] }
    end

    def options(format, file, opts = {})
      opts[:threads] = 2 unless opts[:threads]
      opts.merge!(codec(format))
      opts.merge!(custom_options(format, file, opts))
    end

    def transcoder_options
      {}
    end

    def movie path
      ::FFMPEG::Movie.new path
    end
  end
end
