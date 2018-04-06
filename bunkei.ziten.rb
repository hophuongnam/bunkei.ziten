require 'nokogiri'
require 'fullwidth'
require 'json'
require 'securerandom'

def mergeAdjiacent (doc, clName, linebreak)
    # linebreak: true, false
    # true to use linebreak as separator

    # α = <ruby>
    # γ = <rt>
    # δ = </rt></ruby>
    # <ruby> KANJI <rt> KANA </rt></ruby>
    # λ μ = dotted underline
    # ξ π = comment (translation)

    content = ""
    elementToRemoved = []

    doc.xpath("//*[@class='#{clName}']").each do |i|
        if i['br'] == 'yes' and not linebreak
            i.content = "$#{i.content}"
        end

        unless i.xpath("./commentReference").empty?
            i.content = "ξ#{i.at_xpath('./commentReference')['id']}π"
        end

        unless i.xpath("./ruby").empty?
            begin
                ruby = i.at_xpath("./ruby/rubyBase").text
                furi = i.at_xpath("./ruby/rt").text

                if i.xpath("./rPr[u[@val='thick']]").empty?
                    content += "α#{ruby}γ#{furi}δ"
                else
                    content += "βα#{ruby}γ#{furi}δθ"
                end
            rescue
                puts i
            end
        else
            if i.xpath("./rPr[u[@val='dotted']]").empty?
                content += i.content
            else
                content += "λ#{i.content}μ"
            end
        end

        elementToRemoved.push i

        if i.next_element.nil? or i.next_element['class'] != "#{clName}" or (i.next_element['br'] == 'yes' and linebreak)
            elementToRemoved.pop
            i.inner_html = content
            content = ""
        end
    end
    elementToRemoved.each {|s| s.remove}
end

def convertFile (f)
    commentSVG = 'data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9Im5vIj8+CjwhRE9DVFlQRSBzdmcgUFVCTElDICItLy9XM0MvL0RURCBTVkcgMS4xLy9FTiIgImh0dHA6Ly93d3cudzMub3JnL0dyYXBoaWNzL1NWRy8xLjEvRFREL3N2ZzExLmR0ZCI+CjxzdmcgdmVyc2lvbj0iMS4xIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiBwcmVzZXJ2ZUFzcGVjdFJhdGlvPSJ4TWlkWU1pZCBtZWV0IiB2aWV3Qm94PSIwIDAgMzAwIDI0OSIgd2lkdGg9IjMwMCIgaGVpZ2h0PSIyNDkiPjxkZWZzPjxwYXRoIGQ9Ik04NS4wMiAzNS44NkM4NS4wMiAzNS44NiA4NS4wMiAzNS44NiA4NS4wMiAzNS44NkMxMTEuNTUgMzUuODYgMTI2LjI4IDM1Ljg2IDEyOS4yMyAzNS44NkMxNzguOTcgMzUuODYgMjA2LjYgMzUuODYgMjEyLjEzIDM1Ljg2QzIxNy41MSAzNS44NiAyMjIuNjYgMzguMDUgMjI2LjQ2IDQxLjk0QzIzMC4yNiA0NS44MyAyMzIuNCA1MS4xMSAyMzIuNCA1Ni42MUMyMzIuNCA2MC4wNyAyMzIuNCA3Ny4zNyAyMzIuNCAxMDguNDlDMjMyLjQgMTA4LjQ5IDIzMi40IDEwOC40OSAyMzIuNCAxMDguNDlDMjMyLjQgMTI3LjE3IDIzMi40IDEzNy41NCAyMzIuNCAxMzkuNjJDMjMyLjQgMTM5LjYyIDIzMi40IDEzOS42MiAyMzIuNCAxMzkuNjJDMjMyLjQgMTUxLjA4IDIyMy4zMiAxNjAuMzcgMjEyLjEzIDE2MC4zN0MyMDYuNiAxNjAuMzcgMTc4Ljk3IDE2MC4zNyAxMjkuMjMgMTYwLjM3QzEyNS4zOCAxNjMuODkgMTA2LjEzIDE4MS40OCA3MS40NyAyMTMuMTRDNzkuNiAxODEuNDggODQuMTIgMTYzLjg5IDg1LjAyIDE2MC4zN0M3OS40OSAxNjAuMzcgNzYuNDIgMTYwLjM3IDc1LjggMTYwLjM3QzY0LjYxIDE2MC4zNyA1NS41NCAxNTEuMDggNTUuNTQgMTM5LjYyQzU1LjU0IDEzOS42MiA1NS41NCAxMzkuNjIgNTUuNTQgMTM5LjYyQzU1LjU0IDEzNy41NCA1NS41NCAxMjcuMTcgNTUuNTQgMTA4LjQ5QzU1LjU0IDEwOC40OSA1NS41NCAxMDguNDkgNTUuNTQgMTA4LjQ5QzU1LjU0IDc3LjM2IDU1LjU0IDYwLjA3IDU1LjU0IDU2LjYxQzU1LjU0IDU2LjYxIDU1LjU0IDU2LjYxIDU1LjU0IDU2LjYxQzU1LjU0IDQ1LjE1IDY0LjYxIDM1Ljg2IDc1LjggMzUuODZDNzYuNDIgMzUuODYgNzkuNDkgMzUuODYgODUuMDIgMzUuODZaIiBpZD0iZXo0SzJVSWxVIj48L3BhdGg+PC9kZWZzPjxnPjxnPjxnPjx1c2UgeGxpbms6aHJlZj0iI2V6NEsyVUlsVSIgb3BhY2l0eT0iMSIgZmlsbD0iIzAwMDAwMCIgZmlsbC1vcGFjaXR5PSIwIj48L3VzZT48Zz48dXNlIHhsaW5rOmhyZWY9IiNlejRLMlVJbFUiIG9wYWNpdHk9IjEiIGZpbGwtb3BhY2l0eT0iMCIgc3Ryb2tlPSIjMjIyMjIyIiBzdHJva2Utd2lkdGg9IjEwIiBzdHJva2Utb3BhY2l0eT0iMSI+PC91c2U+PC9nPjwvZz48L2c+PC9nPjwvc3ZnPg=='

    doc = Nokogiri::XML(File.open(f))
    doc.remove_namespaces!

    #
    # Build translation database
    # use 'heading' styles instead of 'highlight' because 'heading' will affect whole paragraph
    # 'Heading2' => Vietnamese
    # 'Heading3' => English
    #
    commentsFile = "#{f.chomp("xml")}comments.xml"
    commentsHash = {}

    if File.file? commentsFile
        commentsDoc = Nokogiri::XML(File.open(commentsFile))
        commentsDoc.remove_namespaces!

        commentsDoc.xpath("//comment").each do |c|
            uuid = SecureRandom.uuid
            commentsHash[c['id']] = uuid

            h = {}
            commmentsContentVI = ''
            commmentsContentEN = ''

            c.xpath("./p[pPr[pStyle[@val='Heading2']]]").each {|p|
                commmentsContentVI += "<div>#{p.content}</div>"
                commmentsContentVI.gsub!("'", "&#39;")
                commmentsContentVI.gsub!('"', "&#34;")
            }

            c.xpath("./p[pPr[pStyle[@val='Heading3']]]").each {|p|
                commmentsContentEN += "<div>#{p.content}</div>"
                commmentsContentEN.gsub!("'", "&#39;")
                commmentsContentEN.gsub!('"', "&#34;")
            }

            h['vi'] = commmentsContentVI unless commmentsContentVI.empty?
            h['en'] = commmentsContentEN unless commmentsContentEN.empty?

            $trans[uuid] = h unless h.empty?
        end
    end

    #
    # Initial Cleanup
    #
    doc.xpath("//bookmarkStart").remove
    doc.xpath("//bookmarkEnd").remove
    doc.xpath("//sectPr").remove
    doc.xpath("//*").each do |d|
        d.remove_attribute "rsidR"
        d.remove_attribute "rsidRPr"
        d.remove_attribute "textId"
        d.remove_attribute "rsidR"
        d.remove_attribute "rsidRDefault"
        d.remove_attribute "rsidP"
    end

    doc.xpath("//commentRangeStart").remove
    doc.xpath("//commentRangeEnd").remove

    #
    # Mark all linebreak
    #
    doc.xpath("//r[br]").each {|r|
        r['br'] = 'yes'
    }

    #
    # <p> cannot have block elements as child
    # Convert all <p> into <div>, and set class to 'item', each item is a grammar point or a header
    # 
    doc.xpath("/document/body/p").each do |r|
        r.name = "div"
        r['class'] = 'item'
    end

    #
    # Add class 'heading' to every grammar points
    #
    doc.xpath("/document/body/div[pPr[pStyle[@val='Heading3']]]").each do |h|
        h['class'] = 'heading'
    end

    #
    # Under each 'item', make every <r> to be <span class='content'>
    #
    doc.xpath("/document/body/div/r").each do |r|
        r.name = "span"
        r['class'] = "content"
    end

    #
    # Any <span class=content> with border attribute are make <div class='border'>
    #
    doc.xpath("//span[@class='content'][rPr[bdr]]").each {|r| 
        r['class'] = "border"
        r.name = 'div'
    }

    #
    # Any <span class=content> with highlight green are make <span class='examples'>
    #
    doc.xpath("//span[@class='content'][rPr[highlight[@val='green']]]").each {|r| r['class'] = "examples"}

    #
    # Any <span class=content> with highlight yellow are make <div class='explains'>
    #
    # doc.xpath("//span[@class='content'][rPr[highlight[@val='yellow']]]").each {|r| r['class'] = "explains"}
    doc.xpath("//span[@class='content'][rPr[highlight[@val='yellow']]]").each {|r|
        r['class'] = "explains"
        r.name = 'div'
    }

    #
    # Any <span class=content> with highlight cyan are make <span class='wrong'>
    #
    doc.xpath("//span[@class='content'][rPr[highlight[@val='cyan']]]").each {|r| r['class'] = "wrong"}

    #
    # Any <span class=content> with highlight magenta are make <span class='right'>
    #
    doc.xpath("//span[@class='content'][rPr[highlight[@val='magenta']]]").each {|r| r['class'] = "right"}

    #
    # Any <span class=content> with highlight lightGray are make <span class='sample'>
    #
    doc.xpath("//span[@class='content'][rPr[highlight[@val='lightGray']]]").each {|r| r['class'] = "sample"}

    #
    # Any <span class=content> with highlight darkGray are make <span class='keyword'>
    #
    doc.xpath("//span[@class='content'][rPr[highlight[@val='darkGray']]]").each {|r| r['class'] = "keyword"}

    #
    # Any <span class=content> with highlight darkCyan are make <span class='kanji'>
    #
    doc.xpath("//span[@class='content'][rPr[highlight[@val='darkCyan']]]").each {|r| r['class'] = "kanji"}

    #
    # Make commentReference element's class the same as the next element's class
    #
    doc.xpath("//span[@class='content'][commentReference]").each {|r|
        r['class'] = r.next_element['class']
    }

    mergeAdjiacent doc, "examples" , false
    mergeAdjiacent doc, "right"    , false
    mergeAdjiacent doc, "wrong"    , false
    mergeAdjiacent doc, "sample"   , false
    mergeAdjiacent doc, "border"   , true
    mergeAdjiacent doc, "explains" , true
    mergeAdjiacent doc, "keyword"  , true
    mergeAdjiacent doc, "kanji"    , true

    doc.xpath("//rPr").remove
    doc.xpath("//pPr").remove

    #
    # Split Examples into Sentences
    #
    doc.xpath("//*[@class='examples']").each do |e|
        if e.content =~ /[①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳]/
            dummy = e.add_next_sibling "<dummy>"
            table = dummy[0].add_child "<div class=examples></div>"
            e.content.scan(/[①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳].+?(?=(?:[①②③④⑤⑥⑦⑧⑨⑩⑪⑫⑬⑭⑮⑯⑰⑱⑲⑳]|$))/) do |m|
                tableRow = table[0].add_child "<span class=sentence></span>"
                sentenceNumber = tableRow[0].add_child "<span class=sentenceHeader style='white-space: nowrap;'></span>"
                sentence       = tableRow[0].add_child "<span class=sentenceContent></span>"
                scN = m[0, 1]
                m = m[1..-1]
                sentenceNumber[0].content = "#{scN}　"
                m.chomp! "$"
                if /^\$/.match(m)
                	m = m[1..-1]
                end
                m.gsub! "\u3000", ""
                sentence[0].content = m
            end
            e.swap table
            dummy.remove
        end
    end

    #
    # Convert to table-like
    #
    doc.xpath("//*[@class='sample']").each do |e|
        dummy = e.add_next_sibling "<dummy>"
        table = dummy[0].add_child "<div class=examples></div>"
        tableRow = table[0].add_child "<span class=sentence></span>"
        sampleMark = tableRow[0].add_child "<span class=sentenceHeader style='white-space: nowrap;'></span>"
        sample     = tableRow[0].add_child "<span class=sentenceContent></span>"
        content = e.content
        content.chomp! "$"
        if /^\$/.match(content)
            content = content[1..-1]
        end
        content.gsub! "\u3000", ""
        sample[0].content = content
        e.swap table
        dummy.remove
    end

    doc.xpath("//*[@class='right']").each do |e|
        dummy = e.add_next_sibling "<dummy>"
        table = dummy[0].add_child "<div class=examples></div>"
        tableRow = table[0].add_child "<span class=sentence></span>"
        sampleMark = tableRow[0].add_child "<span class=sentenceHeader style='white-space: nowrap;'></span>"
        sample     = tableRow[0].add_child "<span class=sentenceContent></span>"
        content = e.content
        content.chomp! "$"
        if /^\$/.match(content)
            content = content[1..-1]
        end
        content.gsub! "\u3000", ""
        sample[0].content = content
        e.swap table
        dummy.remove
    end

    doc.xpath("//*[@class='wrong']").each do |e|
        dummy = e.add_next_sibling "<dummy>"
        table = dummy[0].add_child "<div class=examples></div>"
        tableRow = table[0].add_child "<span class=sentence></span>"
        sampleMark = tableRow[0].add_child "<span class=sentenceHeader style='white-space: nowrap;'></span>"
        sample     = tableRow[0].add_child "<span class=sentenceContent></span>"
        content = e.content
        content.chomp! "$"
        if /^\$/.match(content)
            content = content[1..-1]
        end
        content.gsub! "\u3000", ""
        sample[0].content = content
        e.swap table
        dummy.remove
    end


    #
    # Tidy up 'heading' by removing '【' and ' 】'
    #
    doc.xpath("//div[@class='heading']/*[@class='keyword']").each {|s| s.content = s.content.gsub("【", "").gsub("】", "")}

    #
    # remove spacebar element
    #
    doc.xpath("//*[@class='explains']").each {|r| r.remove if r.content == "\u3000"}

    #
    # Remove remaining 'content' and 'br'
    #
    doc.xpath("//*[@class='content']").remove
    doc.xpath("//*[@br='yes']").remove

    #
    # Cleanup and add ID for main, outer <div>
    #
    doc.xpath("//div[@class='item']").each {|s| s.remove_attribute "paraId"}
    doc.xpath("//div[@class='also']").each {|s| s.remove_attribute "paraId"}
    doc.xpath("//div[@class='heading']").each {|s|
        s.remove_attribute "rsidP"
        s['id'] = s['paraId']
        s.remove_attribute "paraId"
    }

    #
    # Insert callout for translation
    #

    doc.xpath("//*[@class='border']").each do |s|
        if s.content.include? "ξ"
            s.content.scan(/ξ.+π/) do |m|
                commentID = m[1 .. -2]
                uuid = commentsHash[commentID]
                newContent = s.content.gsub m, ""
                imgVI = ""
                imgEN = ""
                
                if $trans.has_key? uuid
                    imgVI = "<img class='vi translation translation-off' src=#{commentSVG} data-vi=#{uuid}>" if $trans[uuid].has_key? 'vi'
                    imgEN = "<img class='en translation translation-off' src=#{commentSVG} data-en=#{uuid}>" if $trans[uuid].has_key? 'en'
                    s.previous = "<div class=border><span>#{newContent}</span>#{imgVI}#{imgEN}</div>"
                else
                    s.previous = "<div class=border><span>#{newContent}</span></div>"
                end
            end
        else
            s.previous = "<div class=border><span>#{s.content}</span></div>"
        end
        s.remove
    end

    doc.xpath("//*[@class='sentenceContent']").each do |s|
        s.content.scan(/ξ.+π/) do |m|
            commentID = m[1 .. -2]
            uuid = commentsHash[commentID]
            newContent = s.content.gsub m, ""
            imgVI = ""
            imgEN = ""

            if $trans.has_key? uuid
                imgVI = "<img class='vi translation translation-off' src=#{commentSVG} data-vi=#{uuid}>" if $trans[uuid].has_key? 'vi'
                imgEN = "<img class='en translation translation-off' src=#{commentSVG} data-en=#{uuid}>" if $trans[uuid].has_key? 'en'
                s.previous = "<span class=sentenceContent>#{newContent}#{imgVI}#{imgEN}</span>"
            else
                s.previous = "<span class=sentenceContent>#{newContent}</span>"
            end
            s.remove
        end
    end

    doc.xpath("//*[@class='explains']").each do |s|
        s.content.scan(/ξ.+π/) do |m|
            commentID = m[1 .. -2]
            uuid = commentsHash[commentID]
            newContent = s.content.gsub m, ""
            imgVI = ""
            imgEN = ""

            if $trans.has_key? uuid
                imgVI = "<img class='vi translation translation-off' src=#{commentSVG} data-vi=#{uuid}>" if $trans[uuid].has_key? 'vi'
                imgEN = "<img class='en translation translation-off' src=#{commentSVG} data-en=#{uuid}>" if $trans[uuid].has_key? 'en'
                s.previous = "<div class=explains>#{newContent}#{imgVI}#{imgEN}</div>"
            else
                s.previous = "<div class=explains>#{newContent}</div>"
            end
            s.remove
        end
    end

    doc.xpath("//div[@class='heading']/span[@class='keyword']").each do |s|
        s.content.scan(/ξ.+π/) do |m|
            commentID = m[1 .. -2]
            uuid = commentsHash[commentID]
            newContent = s.content.gsub m, ""
            imgVI = ""
            imgEN = ""

            s.previous = "<span class=keyword>#{newContent}</span>"
            if $trans.has_key? uuid
                s.previous = "<img class='vi translation translation-off' src=#{commentSVG} data-vi=#{uuid}>" if $trans[uuid].has_key? 'vi'
                s.previous = "<img class='en translation translation-off' src=#{commentSVG} data-en=#{uuid}>" if $trans[uuid].has_key? 'en'
            end
            s.remove
        end
    end
    
    #
    # Build TOC
    #
    doc.xpath("//div[@class='heading']").each do |d|
        keyword = d.xpath("span[@class='keyword']").text
        h = {
            "keyword" => keyword.to_fullwidth,
            "id" => d['id']
        }
        $tocDict << h
    end

    #
    # Convert to full width
    #
    doc.search("//text()").each {|t| t.content = t.content.to_fullwidth}

    #
    # α = <ruby>
    # γ = <rt>
    # δ = </rt></ruby>
    # <ruby> KANJI <rt> KANA </rt></ruby>
    # β θ = thick underline
    # λ μ = dotted underline
    # ξ π = comment (translation)
    #    
    itemSet = []
    attrID = ""
    content = ""
    doc.xpath("/document/body/div").each do |d|
        if d.has_attribute? "id"
            attrID = d['id']
            d.remove_attribute "id"
        end
        itemSet << d
        if d.next_element.nil? or d.next_element['class'] == "heading"
            itemSet.each do |i|
                content += i.to_html
            end

            content.gsub! 'α', '<ruby>'
            content.gsub! 'γ', '<rt>'
            content.gsub! 'δ', '</rt></ruby>'

            content.gsub! 'μλ', ""

            content.gsub! '＄', '<br>'

            $dict[attrID] = content
            itemSet = []
            content = ""
        end
    end
end

$tocDict = []
$dict = {}
$trans = {}

convertFile "bunkei.ziten.aiueo.docx.xml"

convertFile "bunkei.ziten.kakikukeko.docx.xml"
convertFile "bunkei.ziten.sashisuseso.docx.xml"
convertFile "bunkei.ziten.tachitsu.docx.xml"
convertFile "bunkei.ziten.te.docx.xml"
convertFile "bunkei.ziten.to.docx.xml"
convertFile "bunkei.ziten.na.docx.xml"
convertFile "bunkei.ziten.ninuneno.docx.xml"
convertFile "bunkei.ziten.hahifuheho.docx.xml"
convertFile "bunkei.ziten.mamimumemo.docx.xml"
convertFile "bunkei.ziten.last.docx.xml"

version = Time.now.to_i
$dict['version'] = version

#
# Write to file
#
File.open("/Data/time4vps.html/bunkei.ziten.version.js", "w") {|f| f.write "version = #{version};"}
File.open("/Data/time4vps.html/toc.json", "w") {|f| f.write $tocDict.to_json}
File.open("/Data/time4vps.html/dict.json", "w") {|f| f.write $dict.to_json}
File.open("/Data/time4vps.html/trans.json", "w") {|f| f.write $trans.to_json}
puts "Done!"
