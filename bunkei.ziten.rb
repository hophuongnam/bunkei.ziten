require 'nokogiri'
require 'fullwidth'
require 'json'
# require "uuidtools"
# require 'couchrest'

def mergeAdjiacent (doc, clName)
    items = doc.xpath("//*[@class='#{clName}']"); nil
    content = ""
    elementToRemoved = []
    items.each do |i|
        unless i.xpath("./ruby").empty?
            begin
                ruby = i.at_xpath("./ruby/rubyBase").text
                furi = i.at_xpath("./ruby/rt").text
                # α = <ruby>
                # γ = <rt>
                # δ = </rt></ruby>
                # <ruby> KANJI <rt> KANA </rt></ruby>
                content += "α#{ruby}γ#{furi}δ"
            rescue
                puts i
            end
        else
            content += i.content
        end
        elementToRemoved.push i
        if i.next_element.nil? or i.next_element['class'] != "#{clName}"
            elementToRemoved.pop
            i.inner_html = content
            # i.inner_html = content.gsub(/\s+/, "")
            content = ""
        end
    end
    elementToRemoved.each {|s| s.remove}; nil
end

def convertFile (f, tocDict, dict)
    commentSVG = 'data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0iVVRGLTgiIHN0YW5kYWxvbmU9Im5vIj8+CjwhRE9DVFlQRSBzdmcgUFVCTElDICItLy9XM0MvL0RURCBTVkcgMS4xLy9FTiIgImh0dHA6Ly93d3cudzMub3JnL0dyYXBoaWNzL1NWRy8xLjEvRFREL3N2ZzExLmR0ZCI+CjxzdmcgdmVyc2lvbj0iMS4xIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHhtbG5zOnhsaW5rPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5L3hsaW5rIiBwcmVzZXJ2ZUFzcGVjdFJhdGlvPSJ4TWlkWU1pZCBtZWV0IiB2aWV3Qm94PSIwIDAgMzAwIDI0OSIgd2lkdGg9IjMwMCIgaGVpZ2h0PSIyNDkiPjxkZWZzPjxwYXRoIGQ9Ik04NS4wMiAzNS44NkM4NS4wMiAzNS44NiA4NS4wMiAzNS44NiA4NS4wMiAzNS44NkMxMTEuNTUgMzUuODYgMTI2LjI4IDM1Ljg2IDEyOS4yMyAzNS44NkMxNzguOTcgMzUuODYgMjA2LjYgMzUuODYgMjEyLjEzIDM1Ljg2QzIxNy41MSAzNS44NiAyMjIuNjYgMzguMDUgMjI2LjQ2IDQxLjk0QzIzMC4yNiA0NS44MyAyMzIuNCA1MS4xMSAyMzIuNCA1Ni42MUMyMzIuNCA2MC4wNyAyMzIuNCA3Ny4zNyAyMzIuNCAxMDguNDlDMjMyLjQgMTA4LjQ5IDIzMi40IDEwOC40OSAyMzIuNCAxMDguNDlDMjMyLjQgMTI3LjE3IDIzMi40IDEzNy41NCAyMzIuNCAxMzkuNjJDMjMyLjQgMTM5LjYyIDIzMi40IDEzOS42MiAyMzIuNCAxMzkuNjJDMjMyLjQgMTUxLjA4IDIyMy4zMiAxNjAuMzcgMjEyLjEzIDE2MC4zN0MyMDYuNiAxNjAuMzcgMTc4Ljk3IDE2MC4zNyAxMjkuMjMgMTYwLjM3QzEyNS4zOCAxNjMuODkgMTA2LjEzIDE4MS40OCA3MS40NyAyMTMuMTRDNzkuNiAxODEuNDggODQuMTIgMTYzLjg5IDg1LjAyIDE2MC4zN0M3OS40OSAxNjAuMzcgNzYuNDIgMTYwLjM3IDc1LjggMTYwLjM3QzY0LjYxIDE2MC4zNyA1NS41NCAxNTEuMDggNTUuNTQgMTM5LjYyQzU1LjU0IDEzOS42MiA1NS41NCAxMzkuNjIgNTUuNTQgMTM5LjYyQzU1LjU0IDEzNy41NCA1NS41NCAxMjcuMTcgNTUuNTQgMTA4LjQ5QzU1LjU0IDEwOC40OSA1NS41NCAxMDguNDkgNTUuNTQgMTA4LjQ5QzU1LjU0IDc3LjM2IDU1LjU0IDYwLjA3IDU1LjU0IDU2LjYxQzU1LjU0IDU2LjYxIDU1LjU0IDU2LjYxIDU1LjU0IDU2LjYxQzU1LjU0IDQ1LjE1IDY0LjYxIDM1Ljg2IDc1LjggMzUuODZDNzYuNDIgMzUuODYgNzkuNDkgMzUuODYgODUuMDIgMzUuODZaIiBpZD0iZXo0SzJVSWxVIj48L3BhdGg+PC9kZWZzPjxnPjxnPjxnPjx1c2UgeGxpbms6aHJlZj0iI2V6NEsyVUlsVSIgb3BhY2l0eT0iMSIgZmlsbD0iIzAwMDAwMCIgZmlsbC1vcGFjaXR5PSIwIj48L3VzZT48Zz48dXNlIHhsaW5rOmhyZWY9IiNlejRLMlVJbFUiIG9wYWNpdHk9IjEiIGZpbGwtb3BhY2l0eT0iMCIgc3Ryb2tlPSIjMjIyMjIyIiBzdHJva2Utd2lkdGg9IjEwIiBzdHJva2Utb3BhY2l0eT0iMSI+PC91c2U+PC9nPjwvZz48L2c+PC9nPjwvc3ZnPg=='

    file = File.open f
    doc = Nokogiri::XML file; nil
    doc.remove_namespaces!; nil

    #
    # Initial Cleanup
    #
    doc.xpath("//bookmarkStart").remove; nil
    doc.xpath("//bookmarkEnd").remove; nil
    doc.xpath("//sectPr").remove; nil    
    doc.xpath("//*").each do |d|
        d.remove_attribute "rsidR"
        d.remove_attribute "rsidRPr"
        d.remove_attribute "textId"
        d.remove_attribute "rsidR"
        d.remove_attribute "rsidRDefault"
        d.remove_attribute "rsidP"
    end

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
    # Some grammar points are in fact references, change class of these grammar points to 'also'
    #
    doc.xpath("//*[@class='heading']").each do |h|
        if h.next_element.name == 'div' and h.next_element['class'] == "heading"
            h['class'] = 'also'
        end
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
    # Border with bold are make class 'subheader'
    #
    # doc.xpath("//span[@class='border'][rPr[b]]").each {|r| r['class'] = "subheader"}

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

    # Any <span class=content> with highlight darkCyan are make <span class='kanji'>
    doc.xpath("//span[@class='content'][rPr[highlight[@val='darkCyan']]]").each {|r| r['class'] = "kanji"}

    # Any <span class=content> with highlight darkRed are make <span class='vi'>
    doc.xpath("//span[@class='content'][rPr[highlight[@val='darkRed']]]").each {|r|
        r['class'] = "vi"
        # r.name = "img"
        # r['data-vi'] = r.content
        # r.content = ""
        # r['src'] = "vi.png"
    }

    # Any <span class=content> with highlight darkYellow are make <span class='en'>
    doc.xpath("//span[@class='content'][rPr[highlight[@val='darkYellow']]]").each {|r|
        r['class'] = "en"
        # r.name = "img"
        # r['data-en'] = r.content
        # r.content = ""
        # r['src'] = "en.png"
    }

    mergeAdjiacent doc, "border"
    # mergeAdjiacent doc, "subheader"
    mergeAdjiacent doc, "examples"
    mergeAdjiacent doc, "explains"
    mergeAdjiacent doc, "right"
    mergeAdjiacent doc, "wrong"
    mergeAdjiacent doc, "sample"
    mergeAdjiacent doc, "content"
    mergeAdjiacent doc, "keyword"
    # mergeAdjiacent doc, "arrow"
    mergeAdjiacent doc, "kanji"
    mergeAdjiacent doc, "vi"
    mergeAdjiacent doc, "en"

    doc.xpath("//rPr").remove; nil
    doc.xpath("//pPr").remove; nil

    #
    # Move content to data attributes
    #
    doc.xpath("//*[@class='vi']").each { |r|
        r['data-vi'] = r.content
        r.content = ''
        r.name = 'img'
        r['src'] = "#{commentSVG}"
    }

    doc.xpath("//*[@class='en']").each { |r|
        r['data-en'] = r.content
        r.content = ''
        r.name = 'img'
        r['src'] = "#{commentSVG}"
    }

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
                m.gsub! "　", ""
                sentence[0].content = m
            end
            e.swap table
            dummy.remove
        end
    end

    #
    # Convert to table-like
    #
    # α = <ruby>
    # γ = <rt>
    # δ = </rt></ruby>
    #
    doc.xpath("//*[@class='sample']").each do |e|
        dummy = e.add_next_sibling "<dummy>"
        table = dummy[0].add_child "<div class=examples></div>"
        tableRow = table[0].add_child "<span class=sentence></span>"
        sampleMark = tableRow[0].add_child "<span class=sentenceHeader style='white-space: nowrap;'></span>"
        sample     = tableRow[0].add_child "<span class=sentenceContent></span>"
        # sampleMark[0].content = "（α例γれいδ）"
        content = e.content
        # content.gsub! "（α例γれいδ）", ""
        content.chomp! "$"
        if /^\$/.match(content)
            content = content[1..-1]
        end
        content.gsub! "　", ""
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
        # sampleMark[0].content = "（α正γただしδ）"
        content = e.content
        # content.gsub! "（α正γただしδ）", ""
        content.chomp! "$"
        if /^\$/.match(content)
            content = content[1..-1]
        end
        content.gsub! "　", ""
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
        # sampleMark[0].content = "（α誤γあやまδ）"
        content = e.content
        # content.gsub! "（α誤γあやまδ）", ""
        content.chomp! "$"
        if /^\$/.match(content)
            content = content[1..-1]
        end
        content.gsub! "　", ""
        sample[0].content = content
        e.swap table
        dummy.remove
    end

    #
    # CRLF markers in 'explains'
    # Also remove spacebar
    #
    doc.xpath("//*[@class='explains']").each do |s|
        if /\$$/.match(s.content)
            s.content = s.content.chomp "$"
        end
        if /^\$/.match(s.content)
            s.content = s.content[1..-1]
        end
        if /\u3000$/.match(s.content)
            s.content = s.content.chomp "\u3000"
        end
        if /^\u3000/.match(s.content)
            s.content = s.content[1..-1]
        end
        if s.content.include? "$"
            # s.remove_attribute "class"
            # s.name = "div"
            # content = s.content
            # s.content = ""
            # content.split("$").each do |c|
            #    child = s.add_child "<span class=explains></span>"
            #    child = s.add_child "<div class=explains></div>"
            #    child[0].content = c
            # end
            s.content.split("$").each do |c|
                s.previous = "<div class=explains>#{c}</div>"
            end
            s.remove
        end
    end

    #
    # Tidy up 'heading' by removing '【' and ' 】'
    #
    doc.xpath("//div[@class='heading']/*[@class='keyword']").each {|s| s.content = s.content.gsub("【", "").gsub("】", "")}

    #
    # remove spacebar element
    #
    doc.xpath("//*[@class='explains']").each {|b| b.remove if b.content == "　"}
    doc.xpath("//*[@class='explains']").each {|b| b.remove if b.content == ""}
    doc.xpath("//*[@class='content']").each {|b| b.remove if b.content == "　"}
    doc.xpath("//*[@class='content']").each {|b| b.remove if b.content == ""}

    #
    # Cleanup and add ID for main, outer <div>
    #
    doc.xpath("//div[@class='item']").each {|s| s.remove_attribute "paraId"}
    doc.xpath("//div[@class='also']").each {|s| s.remove_attribute "paraId"}
    doc.xpath("//div[@class='heading']").each {|s|
        s.remove_attribute "rsidP"
        s['id'] = s['paraId']
        # s['id'] = UUIDTools::UUID.md5_create(UUIDTools::UUID_DNS_NAMESPACE, s.text)
        s.remove_attribute "paraId"
    }

    #
    #
    #
    doc.xpath("//*[@class='sentenceContent']").each do |s|
        if s.content.include? "|"
            a = s.content.split("|")            
            s.previous = "<span class=sentenceContent>#{a[0]}<img class=vi src='#{commentSVG}' data-vi='#{a[1].strip}'></span>"
            s.remove
        end
    end

    doc.xpath("//*[@class='explains']").each do |s|
        if s.content.include? "|"
            a = s.content.split("|")
            s.previous = "<div class=explains>#{a[0]}<img class=vi src='#{commentSVG}' data-vi='#{a[1].strip}'></div>"
            s.remove
        end
    end

    doc.xpath("//*[@class='border']").each do |s|
        if s.content.include? "|"
            a = s.content.split("|")
            s.previous = "<div class=border><span>#{a[0]}</span><img class=vi src='#{commentSVG}' data-vi='#{a[1].strip}'></div>"
        else
            s.previous = "<div class=border><span>#{s.content}</span></div>"
        end
        s.remove
    end
    
    doc.xpath("//div[@class='heading']").each do |d|
        keyword = d.xpath("span[@class='keyword']").text
        h = {
            "keyword" => keyword.to_fullwidth,
            "id" => d['id']
        }
        # h = {
        #    "keyword" => "<span class=tocItem>#{keyword.to_fullwidth}</span>",
        #    "type" => "kana",
        #    "id" => d['id']
        # }
        tocDict << h

        # keyword = d.xpath("span[@class='kanji']").text
        # unless keyword == ""
        #    keyword.gsub! 'α', '<ruby>'
        #    keyword.gsub! 'γ', '<rt>'
        #    keyword.gsub! 'δ', '</rt></ruby>'
        #    h = {
        #        "keyword" => keyword,
        #        "type" => "kanji",
        #        "id" => d['id']
        #    }
        #    tocDict << h
        # end
    end

    #
    # Convert to full width
    #
    doc.search("//text()").each {|t| t.content = t.content.to_fullwidth}

    #
    # α = <ruby>
    # γ = <rt>
    # δ = </rt></ruby>
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

            dict[attrID] = content
            itemSet = []
            content = ""
        end
    end
end

tocDict = []
dict = {}

convertFile "bunkei.ziten.aiueo.docx.xml",       tocDict, dict
convertFile "bunkei.ziten.kakikukeko.docx.xml",  tocDict, dict
convertFile "bunkei.ziten.sashisuseso.docx.xml", tocDict, dict
convertFile "bunkei.ziten.tachitsu.docx.xml",    tocDict, dict
convertFile "bunkei.ziten.te.docx.xml",          tocDict, dict
convertFile "bunkei.ziten.to.docx.xml",          tocDict, dict
convertFile "bunkei.ziten.na.docx.xml",          tocDict, dict
convertFile "bunkei.ziten.ninuneno.docx.xml",    tocDict, dict
convertFile "bunkei.ziten.hahifuheho.docx.xml",  tocDict, dict
convertFile "bunkei.ziten.mamimumemo.docx.xml",  tocDict, dict
convertFile "bunkei.ziten.last.docx.xml",        tocDict, dict
version = Time.now.to_i
dict['version'] = version

#
# Write to file
#
File.open("/Data/time4vps.html/bunkei.ziten.version.js", "w") {|f| f.write "version = #{version};"}
File.open("/Data/time4vps.html/toc.json", "w") {|f| f.write tocDict.to_json}
File.open("/Data/time4vps.html/dict.json", "w") {|f| f.write dict.to_json}

=begin
begin
    @db = CouchRest.database("https://39228207-56cf-4bdf-b993-2b96cb3711f5-bluemix:edc0b864993e75b4dbda70746208ca93ba8fa77af25012499908138b74a752b2@39228207-56cf-4bdf-b993-2b96cb3711f5-bluemix.cloudant.com/bunkei")
    doc = @db.get "update"
rescue
    sleep 5
    retry
end

doc["version"] = version

begin
    @db.save_doc doc
rescue
    sleep 10
    retry
end
=end
