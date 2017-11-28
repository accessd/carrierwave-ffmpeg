describe CarrierWave::FFmpeg do
  class Video; end

  class TestVideoUploader
    include CarrierWave::FFmpeg
    def cached?; end
    def cache_stored_file!; end
    def model
      @video ||= Video.new
    end
  end

  let(:converter) { TestVideoUploader.new }

  describe '.encode' do
    it 'processes the model' do
      expect(TestVideoUploader).to receive(:process).with(encode: ['format', :opts])
      TestVideoUploader.encode('format', :opts)
    end

    it 'does not require options' do
      expect(TestVideoUploader).to receive(:process).with(encode: ['format', {}])
      TestVideoUploader.encode('format')
    end
  end

  describe '#encode' do
    let(:format) { :jpg }
    let(:movie) { double }

    before do
      allow(converter).to receive(:current_path).and_return('video/path/file.mp4')
      allow(movie).to receive(:duration).and_return(100)
      allow(movie).to receive(:frame_rate).and_return(30)

      expect(FFMPEG::Movie).to receive(:new).and_return(movie)
    end

    context 'with no options set' do
      before { expect(File).to receive(:rename) }
      let(:default_frame_num) { 30 * 100 * 10 / 100 }

      it 'calls transcode with correct format options' do
        expect(movie).to receive(:transcode) do |path, opts, codec_opts|
          expect(opts[:custom]).to eq(['-vf', "select=gte(n\\,#{default_frame_num})", '-vframes', 1])

          expect(path).to eq("video/path/tmp_file.#{format}")
        end

        converter.encode(format)
      end
    end

    context 'with resolution option set' do
      before { expect(File).to receive(:rename) }

      it 'calls transcode with correct format options' do
        expect(movie).to receive(:transcode) do |path, opts, codec_opts|
          expect(opts[:resolution]).to eq('640x640')
        end

        converter.encode(format, resolution: '640x640')
      end
    end

    context 'with frame_num option set' do
      before { expect(File).to receive(:rename) }
      let(:frame_num) { 30 }

      it 'uses custom frame_num' do
        expect(movie).to receive(:transcode) do |path, opts, codec_opts|
          expect(opts[:custom]).to eq(['-vf', "select=gte(n\\,#{frame_num})", '-vframes', 1])
        end

        converter.encode(format, frame_num: frame_num)
      end
    end

    context 'with seek option set' do
      before { expect(File).to receive(:rename) }
      let(:seek) { 5 }
      let(:frame_num) { 30 * 100 * seek / 100 }

      it 'uses custom frame_num' do
        expect(movie).to receive(:transcode) do |path, opts, codec_opts|
          expect(opts[:custom]).to eq(['-vf', "select=gte(n\\,#{frame_num})", '-vframes', 1])
        end

        converter.encode(format, seek: seek)
      end
    end
  end
end
