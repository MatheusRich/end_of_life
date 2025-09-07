module EndOfLife
  module VersionDetector
    def file_detectors
      @file_detectors ||= {}
    end

    def detects_from(file, &block)
      file_detectors[file] = block
    end

    def relevant_files = file_detectors.keys

    def detect_all(files)
      files.filter_map { |file| detect(file) }
    end

    def detect(file)
      return if file.read.strip.empty?
      detector = file_detectors[File.basename(file.path)] or return
      version = detector.call(file.read) or return

      return if version.zero?

      version
    end
  end
end
