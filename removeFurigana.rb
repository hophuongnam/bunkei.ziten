# Remove Furigana from Explains

if ARGV[0].nil?
    p "Need Filename"
    exit
end

require 'nokogiri'

def mergeAdjiacent(doc, namespace, clName)
    itemToRemoved = []
    itemSet = []
    doc.xpath("//*[@class='#{clName}']").each do |s|
        itemToRemoved.push s
        itemSet.push s
        if s.next_element.nil? or (not s.next_element.has_attribute?("class")) or s.next_element['class'] != "#{clName}"
            itemToRemoved.pop
            itemSet.pop
            next if itemSet.length == 0
            content = ""
            itemSet.each do |i|
                begin
                    content += i.at_xpath("./w:t", namespace).content
                rescue                    
                    puts i
                end
            end
            content += s.at_xpath("./w:t", namespace).content
            s.at_xpath("./w:t", namespace).content = content
            itemSet = []
        end
    end
    itemToRemoved.each {|s| s.remove}
end

namespace = {'w' => "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}
file = File.open ARGV[0]
doc = Nokogiri::XML file; nil

xmlData = doc.xpath("/pkg:package[1]/pkg:part[3]/pkg:xmlData[1]"); nil
body = xmlData.xpath("./w:document[1]/w:body[1]", namespace); nil

#
# Initial Cleanup
#
doc.xpath("//w:bookmarkStart", namespace).remove; nil
doc.xpath("//w:bookmarkEnd", namespace).remove; nil

body.xpath("./w:p/w:r[w:rPr[w:highlight[@w:val='yellow']]]", namespace).each {|r| r['class'] = 'explains'}
body.xpath("./w:p/w:r[w:rPr[w:highlight[@w:val='green']]]", namespace).each {|r| r['class'] = 'examples'}
body.xpath("./w:p/w:r[w:rPr[w:highlight[@w:val='cyan']]]", namespace).each {|r| r['class'] = 'wrong'}
body.xpath("./w:p/w:r[w:rPr[w:highlight[@w:val='magenta']]]", namespace).each {|r| r['class'] = 'right'}
body.xpath("./w:p/w:r[w:rPr[w:highlight[@w:val='lightGray']]]", namespace).each {|r| r['class'] = 'sample'}

def removeFuri(doc, namespace, clName, color)
    doc.xpath("//*[@class='#{clName}']").each {|r|
    # doc.xpath("//*[@class='explains']").each {|r|
        ruby = r.at_xpath("./w:ruby/w:rubyBase", namespace)
        if ruby
            str = %Q{
                <w:r w:rsidRPr="000A5638">
                    <w:rPr>
                        <w:rFonts w:hint="eastAsia"/>
                        <w:highlight w:val="#{color}"/>
                    </w:rPr>
                    <w:t>#{ruby.content}</w:t>
                </w:r>
            }
            r.previous = str
            r.remove
        end
    }
end

# mergeAdjiacent doc, namespace, 'explains'
removeFuri doc, namespace, 'explains', "yellow"
removeFuri doc, namespace, 'examples', "green"
removeFuri doc, namespace, 'wrong', "cyan"
removeFuri doc, namespace, 'right', "magenta"
removeFuri doc, namespace, 'sample', "lightGray"

File.open(ARGV[0], "w") {|f| f.write doc}

# Raise Furigana distance
#fileN = "bunkei.ziten.resaved.xml"
#output = File.read fileN; nil
#output.gsub! '<w:hpsRaise w:val="16"/>', '<w:hpsRaise w:val="22"/>'; nil
#File.open(fileN, "w") {|f| f.write output}
