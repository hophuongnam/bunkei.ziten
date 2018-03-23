# Raise Furigana distance
output = File.read ARGV[0]
output.gsub! '<w:hpsRaise w:val="16"/>', '<w:hpsRaise w:val="22"/>'
output.gsub! '<w:hps w:val="16"/>', '<w:hps w:val="10"/>'
# output.gsub! '>', '＞'
# output.gsub! '<', '＜'
File.open(ARGV[0], "w") {|f| f.write output}