require 'nkf'
require "furigana"
require 'nokogiri'

if ARGV[0].nil?
    p "Need Filename"
    exit
end

# Input "程度が激しかったり、秩序がない様子を表す。「やたらと」も使う。「むやみやたらに」「めったやたらに」という言い方もある。"
# Output: ["程度", "が", "激", "しかったり、", "秩序", "がない", "様子", "を", "表", "す。「やたらと」も", "使", "う。 「むやみやたらに」「めったやたらに」という", "言", "い", "方", "もある。"]
def divideKanjiPhrase(str)
    ctype = "nothing"
    output = ""
    group = []
    str.each_char do |c|
        if /\p{Han}/.match(c)
            case ctype
            when "nothing"
                output = c
            when "kanji"
                output += c
            else
                group << output
                output = c
            end

            ctype = "kanji"
        else
            case ctype
            when "nothing"
                output = c
            when "kana"
                output += c
            else
                group << output
                output = c
            end

            ctype = "kana"
        end
    end

    group << output
    group
end

# Input "言い方", "いいかた"
# Output [["言", "い"], ["方", "かた"]]
def kanjiFuri(kanji, furi)
    o = []
    h = furi
    k = divideKanjiPhrase(kanji)
    k.each_index { |x|
        if /\p{Han}/.match k[x]
            o[x] = h[0 .. k[x].length - 1]
            h = h[k[x].length .. -1]
        else
            head, sep, tail = h.partition k[x]
            if head != ""
                o[x - 1] += head
            end
            o[x] = sep
            h = tail
        end
    }
    o[o.length - 1] += h

    output = []
    memo = []
    k.each_index { |x|
        if /\p{Han}/.match k[x]
            memo << k[x]
            memo << o[x]
            output << memo
            memo = []
        end
    }
    output
end


# Input furigantz "程度が激しかったり、秩序がない様子を表す。「やたらと」も使う。「むやみやたらに」「めったやたらに」という言い方もある。"
# Output [["程度", "ていど"], ["激", "はげ"], ["秩序", "ちつじょ"], ["様子", "ようす"], ["表", "あらわ"], ["使", "つか"], ["言", "い"], ["方", "かた"]]
# Return empty array otherwise
def furigantz(s)
    memo = []
    output = []
    Furigana::Mecab.tokenize(s).each do |n|
        if /\p{Han}/.match n[:surface_form]
            yomi = n[:reading]
            if /\p{Hiragana}/.match n[:surface_form]
                kanjiFuri(n[:surface_form], NKF.nkf('-h1 -w', yomi)).each { |x|
                    output << x
                }
            else
                memo << n[:surface_form]
                memo << NKF.nkf('-h1 -w', yomi)
                output << memo
                memo = []
            end
        end
    end
    output
end

def readFuri (str, color, clName)
    # Return array of markup string
    # Return empty array otherwise
    strToMatch = str
    token = furigantz(strToMatch)
    newStrA = []

    return token if token.empty?

    token.each do |t|
        oldPart = t[0]
        newPart = %Q{
            <w:r w:rsidRPr="000A5638">
              <w:rPr>
                <w:highlight w:val="#{color}"/>
              </w:rPr>
              <w:ruby>
                <w:rubyPr>
                  <w:rubyAlign w:val="distributeSpace"/>
                  <w:hps w:val="10"/>
                  <w:hpsRaise w:val="22"/>
                  <w:hpsBaseText w:val="18"/>
                  <w:lid w:val="ja-JP"/>
                </w:rubyPr>
                <w:rt>
                  <w:r w:rsidR="00E24EC8" w:rsidRPr="000A5638">
                    <w:rPr>
                      <w:rFonts w:ascii="Yu Mincho" w:hAnsi="Yu Mincho" w:hint="eastAsia"/>
                      <w:sz w:val="10"/>
                      <w:highlight w:val="#{color}"/>
                    </w:rPr>
                    <w:t>#{t[1]}</w:t>
                  </w:r>
                </w:rt>
                <w:rubyBase>
                  <w:r w:rsidR="00E24EC8" w:rsidRPr="000A5638">
                    <w:rPr>
                      <w:rFonts w:hint="eastAsia"/>
                      <w:highlight w:val="#{color}"/>
                    </w:rPr>
                    <w:t>#{t[0]}</w:t>
                  </w:r>
                </w:rubyBase>
              </w:ruby>
            </w:r>
        }

        head, m, tail =  strToMatch.partition oldPart
        unless head.empty?
            head = %Q{
                <w:r w:rsidRPr="000A5638" class="#{clName}">
                  <w:rPr>
                    <w:rFonts w:hint="eastAsia"/>
                    <w:highlight w:val="#{color}"/>
                  </w:rPr>
                  <w:t>#{head}</w:t>
                </w:r>
            }
            newStrA.push head
        end
        newStrA.push newPart
        strToMatch = tail
    end

    unless strToMatch.empty?
        strToMatch = %Q{
            <w:r w:rsidRPr="000A5638" class="#{clName}">
                <w:rPr>
                    <w:rFonts w:hint="eastAsia"/>
                    <w:highlight w:val="#{color}"/>
                </w:rPr>
                <w:t>#{strToMatch}</w:t>
            </w:r>
        }
        newStrA.push strToMatch
    end
    return newStrA
end

def addFuri(doc, namespace, color, clName)
    doc.xpath("//*[@class='#{clName}']").each do |s|
        newElements = []
        originalText = s.content
        begin
            newElements = readFuri originalText, color, clName
        rescue
            puts originalText
            newElements = []
        end        
        unless newElements.empty?
            newElements.each do |e|
                s.previous = e
            end
            s.remove
        end
    end
end

def mergeAdjiacent(doc, namespace, clName)
    items = doc.xpath("//*[@class='#{clName}']"); nil
    content = ""
    elementToRemoved = []
    items.each do |i|
        content += i.content
        elementToRemoved.push i
        if i.next_element.nil? or i.next_element['class'] != "#{clName}"
            elementToRemoved.pop
            # i.inner_html = content
            i.xpath("./w:t", namespace).children[0].content = content
            content = ""
        end
    end
    elementToRemoved.each {|s| s.remove}; nil
end

namespace = {'w' => "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}
file = File.open ARGV[0]
# file = File.open "bunkei.ziten.aiueo.xml"
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

mergeAdjiacent doc, namespace, 'explains'
mergeAdjiacent doc, namespace, 'examples'
mergeAdjiacent doc, namespace, 'right'
mergeAdjiacent doc, namespace, 'wrong'
mergeAdjiacent doc, namespace, 'sample'

addFuri doc, namespace, 'green', 'examples'
addFuri doc, namespace, 'yellow', 'explains'
addFuri doc, namespace, 'cyan', 'wrong'
addFuri doc, namespace, 'magenta', 'right'
addFuri doc, namespace, 'lightGray', 'sample'

File.open("#{ARGV[0]}.test.xml", "w") {|f| f.write doc}