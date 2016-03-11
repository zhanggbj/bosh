module Bosh::Director
  class Redactor
    REDACT_KEY_NAMES = %w(
      properties
      bosh
    )
        def self.redact_properties(obj, redact = true ,redact_key_is_ancestor = false)
      return obj unless redact
      if redact_key_is_ancestor
        if obj.respond_to?(:key?)
          obj.keys.each{ |key|
            if obj[key].respond_to?(:each)
              redact_properties(obj[key], redact, true)
            else
              obj[key] = '<redacted>'
            end
          }
        elsif obj.respond_to?(:each_index)
          obj.each_index { |i|
            if obj[i].respond_to?(:each)
              redact_properties(obj[i], redact, true)
            else
              obj[i] = '<redacted>'
            end
          }
        end
      else
        if obj.respond_to?(:each)
          obj.each{ |a|
            if obj.respond_to?(:key?) && REDACT_KEY_NAMES.any? { |key| key == a.first } && a.last.respond_to?(:key?)
              redact_properties(a.last, redact, true)
            else
              redact_properties(a.respond_to?(:last) ? a.last : a, redact)
            end

          }
        end
      end

      obj
    end

    def self.mark_properties_for_redaction(obj, redact = true ,redact_key_is_ancestor = false, redaction_marker = '<redact this!!!>' )

      return obj unless redact
      if redact_key_is_ancestor
        if obj.respond_to?(:key?)
          obj.keys.each{ |key|
            if obj[key].respond_to?(:each)
              mark_properties_for_redaction(obj[key], redact, true)
            else
              obj[key] = "#{obj[key]}#{redaction_marker}"
            end
          }
        elsif obj.respond_to?(:each_index)
          obj.each_index { |i|
            if obj[i].respond_to?(:each)
              mark_properties_for_redaction(obj[i], redact, true)
            else
              obj[i] = "#{obj[i]}#{redaction_marker}"
            end
          }
        end
      else
        if obj.respond_to?(:each)
          obj.each{ |a|
            if obj.respond_to?(:key?) && REDACT_KEY_NAMES.any? { |key| key == a.first } && a.last.respond_to?(:key?)
              mark_properties_for_redaction(a.last, redact, true)
            else
              mark_properties_for_redaction(a.respond_to?(:last) ? a.last : a, redact)
            end

          }
        end
      end
      obj
    end

    def self.redact_difflines_marked_for_redaction diff_lines
      redaction_marker = '<redact this!!!>'
      redaction_message = '<redacted>'

      diff_lines.map do |diffline|
      diffline.text.sub!(/(- |\w+:)(#{redaction_marker})(.*?$)/, "#{$1}#{redaction_message}#{3}")
      end

      # almost but not quite!
    end

  end


end
