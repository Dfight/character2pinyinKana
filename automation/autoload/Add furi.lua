local tr = aegisub.gettext
script_name = tr("Add furi")
script_description = tr("添加拼音假名注音")
script_author = "D.Fight"
script_version = 0.1
http = require("luajit-request")
include("unicode.lua")

function add_furi_main(style,language,pinyin_type,kana_type,separate_type,subs)
    if pinyin_type=="无音标" then
        pinyin_type = 0
    elseif pinyin_type=="有音标" then
        pinyin_type = 1
    end
    if kana_type=="片假名" then
        kana_type = "kana"
    elseif kana_type=="平假名" then
        kana_type = "hira"
    elseif kana_type=="罗马音" then
        kana_type = "hepburn"
    end
    for i = 1,#subs do
        aegisub.progress.set((i-1) / #subs * 100)
        local l = subs[i]
        if l.class == "dialogue" and l.style == style then
            lineKara = {}
			for kDur,sylText in string.gmatch(l.text,"{\\[kK](%d+)}([^{]+)") do
			    lineKara[#lineKara+1] = {sylText=sylText,kDur=kDur}
			end
            str = ""
            local url = "http://adhara.cn:13201/"
            for i=1,#lineKara do
                if language=="拼音" then
                    
                    res = http.send(url.."pinyin?text="..lineKara[i].sylText.."&type="..pinyin_type)
                    str = str.."{\\k"..lineKara[i].kDur.."}"..lineKara[i].sylText..separate_type..res.body
                elseif language=="假名" then
                    res = http.send(url.."kana?text="..lineKara[i].sylText.."&type="..kana_type)
                    if res.body==lineKara[i].sylText then
                        str = str.."{\\k"..lineKara[i].kDur.."}"..lineKara[i].sylText
                    else
                        str = str.."{\\k"..lineKara[i].kDur.."}"..lineKara[i].sylText..separate_type..res.body
                    end
                end
            end
            l.text = str
            subs[i] = l
        end
    end
    aegisub.progress.set(100)
end

function add_furi(subs,sel)
    style_name = ""
    for z, i in ipairs(sel) do
        local l = subs[i]
        if style_name == "" then
            style_name = l.style
        end
    end
    dialog_config={
        {class="label",x=0,y=1,height=1,width=1,label="语言"},
        {class="dropdown",x=1,y=1,height=1,width=1,name="language",value="拼音",items={"拼音","假名"}},
        {class="label",x=0,y=2,height=1,width=1,label="拼音类型"},
        {class="dropdown",x=1,y=2,height=1,width=1,name="pinyin_type",value="无音标",items={"无音标","有音标"}},
        {class="label",x=0,y=3,height=1,width=1,label="假名类型"},
        {class="dropdown",x=1,y=3,height=1,width=1,name="kana_type",value="片假名",items={"片假名","平假名","罗马音"}},
        {class="label",x=0,y=4,height=1,width=1,label="拼音类型"},
        {class="dropdown",x=1,y=4,height=1,width=1,name="separate_type",value="|",items={"|","|!","|<","|>"}},
        {class="label",x=0,y=5,height=1,width=2,label="|>为自定义类型,不考虑溢出强制左对齐"},
        {class="label",x=0,y=6,height=1,width=2,label="如需使用,请替换karaskel-auto4.lua文件"},
    }
    btn,result = aegisub.dialog.display(dialog_config,{"确定","取消"})
    if btn=="确定" then
        add_furi_main(style_name,result.language,result.pinyin_type,result.kana_type,result.separate_type,subs)
    end
    aegisub.set_undo_point(script_name)
end


aegisub.register_macro(script_name,script_description,add_furi)