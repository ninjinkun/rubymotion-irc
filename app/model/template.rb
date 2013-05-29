class Template
  attr_accessor :source
  def initialize(source)
    @source = source
  end
  def render(variables)
    unless variables.is_a?(Hash) || variables.is_a?(Array)
      hash = {}
      variables.instance_variables.each {|var| hash[var.to_s.delete("@")] = variables.instance_variable_get(var) }
      variables = hash
    end
    source.split("\n").join.gsub(/\{%\s+(IF|UNLESS|FOR)\s+(\S+?)\s+%\}(.+)\{%\s+END\s+%\}/) do
      matches = Regexp.last_match
      cond = matches[1]
      key = matches[2]
      body = matches[3]
      variable = variables[key]

      if (cond == 'IF' && variable) || (cond == 'UNLESS' && !variable) 
        break Template.new(body).render(variables)
      end

      if cond == 'FOR' && variable.is_a?(Array)
        break variable.map { |item| Template.new(body).render(item) }.join
      end
    end
    .gsub(/\{%\s+(\S+?)\s+%\}/) do
      matches = Regexp.last_match
      variable_key = matches[1]
      variable = variables[variable_key]
      variable && escapeHTML(variable)
    end
  end
  def escapeHTML(string)
    rule = {
      "&" => "&amp;",
      '"' => "&quot;",
      "<" => "&lt;",
      ">" => "&gt;",
      "'" => "&#39;"
    };
    string.gsub(/[&"'<>]/, rule)
  end
end
