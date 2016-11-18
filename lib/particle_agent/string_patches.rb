# Monkey patches to the String class
class String
  # Remove leading whitespace in a HEREDOC (long multiline string)
  def unindent
    gsub(/^#{scan(/^\s*/).min_by(&:length)}/, "")
  end
end
