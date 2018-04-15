require 'nokogiri'

namespace = {'w' => "http://schemas.openxmlformats.org/wordprocessingml/2006/main"}
file = File.open ARGV[0]
doc = Nokogiri::XML file

doc.xpath("//w:r", namespace).each {|r|
    r["class"] = "content"
}

brBorder = %Q{
<w:r xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
    <w:rPr>
        <w:rFonts w:ascii="Tahoma" w:eastAsia="Yu Mincho" w:hAnsi="Tahoma" w:cs="Tahoma" />
        <w:sz w:val="18" />
        <w:szCs w:val="18" />
    </w:rPr>
    <w:br />
</w:r>
}

doc.xpath("//w:r[w:rPr[w:bdr]]", namespace).each {|r|
    r['class'] = "border"
} 

doc.xpath("//*[@class='border']").each { |r|
    if r.previous_element.nil? or r.previous_element["class"] != 'border'
        r.previous = brBorder
    end
}

brExplains = %Q{
<w:r xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
    <w:rPr>
        <w:rFonts w:ascii="Tahoma" w:eastAsia="Yu Mincho" w:hAnsi="Tahoma" w:cs="Tahoma" />
        <w:sz w:val="18" />
        <w:szCs w:val="18" />
        <w:highlight w:val="yellow" />
    </w:rPr>
    <w:br />
</w:r>
}

doc.xpath("//w:r[w:rPr[w:highlight[@w:val='yellow']]]", namespace).each { |r|
    r['class'] = 'explains'
}

doc.xpath("//*[@class='explains']").each { |r|
    if r.previous_element.nil? or r.previous_element["class"] != 'explains'
        r.previous = brExplains
    end
}

brWrong = %Q{
<w:r xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
    <w:rPr>
        <w:rFonts w:ascii="Tahoma" w:eastAsia="Yu Mincho" w:hAnsi="Tahoma" w:cs="Tahoma" />
        <w:sz w:val="18" />
        <w:szCs w:val="18" />
        <w:highlight w:val="cyan" />
    </w:rPr>
    <w:br />
</w:r>
}

doc.xpath("//w:r[w:rPr[w:highlight[@w:val='cyan']]]", namespace).each { |r|
    r['class'] = 'wrong'
}

doc.xpath("//*[@class='wrong']").each { |r|
    if r.previous_element.nil? or r.previous_element["class"] != 'wrong'
        r.previous = brWrong
    end
}

brRight = %Q{
<w:r xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
    <w:rPr>
        <w:rFonts w:ascii="Tahoma" w:eastAsia="Yu Mincho" w:hAnsi="Tahoma" w:cs="Tahoma" />
        <w:sz w:val="18" />
        <w:szCs w:val="18" />
        <w:highlight w:val="magenta" />
    </w:rPr>
    <w:br />
</w:r>
}

doc.xpath("//w:r[w:rPr[w:highlight[@w:val='magenta']]]", namespace).each { |r|
    r['class'] = 'right'
}

doc.xpath("//*[@class='right']").each { |r|
    if r.previous_element.nil? or r.previous_element["class"] != 'right'
        r.previous = brRight
    end
}

brSamples = %Q{
<w:r xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
    <w:rPr>
        <w:rFonts w:ascii="Tahoma" w:eastAsia="Yu Mincho" w:hAnsi="Tahoma" w:cs="Tahoma" />
        <w:sz w:val="18" />
        <w:szCs w:val="18" />
        <w:highlight w:val="lightGray" />
    </w:rPr>
    <w:br />
</w:r>
}

doc.xpath("//w:r[w:rPr[w:highlight[@w:val='lightGray']]]", namespace).each { |r|
    r['class'] = 'samples'
}

doc.xpath("//*[@class='samples']").each { |r|
    if r.previous_element.nil? or r.previous_element["class"] != 'samples'
        r.previous = brSamples
    end
}

brExamples = %Q{
<w:r xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
    <w:rPr>
        <w:rFonts w:ascii="Tahoma" w:eastAsia="Yu Mincho" w:hAnsi="Tahoma" w:cs="Tahoma" />
        <w:sz w:val="18" />
        <w:szCs w:val="18" />
        <w:highlight w:val="green" />
    </w:rPr>
    <w:br />
</w:r>
}

doc.xpath("//w:r[w:rPr[w:highlight[@w:val='green']]]", namespace).each { |r|
    r['class'] = 'examples'
}

doc.xpath("//*[@class='examples']").each { |r|
    if r.previous_element.nil? or r.previous_element["class"] != 'examples' or r.content == "②" or r.content == "③" or r.content == "④" or r.content == "⑤" or r.content == "⑥" or r.content == "⑦" or r.content == "⑧" or r.content == "⑨" or r.content == "⑩" 
        r.previous = brExamples
    end
}

doc.xpath("//w:r", namespace).each {|r|
    r.remove_attribute "class"
}
File.open(ARGV[0], "w") {|f| f.write doc.to_xml}
