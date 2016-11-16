class String
  # Remove leading whitespace in a HEREDOC (long multiline string)
  def unindent 
    gsub(/^#{scan(/^\s*/).min_by{|l|l.length}}/, "")
  end
end

