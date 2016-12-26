# coding:utf-8

doc=
"""
  レファレンス質問収集プログラム
  レファレンス協同データベースより
"""

using DataFrames
using Requests

# 検索結果からidをパース
function id_parse(qid, html, result_base)
  for m in matchall(result_base, html)
    id = match(result_base, m)[1]
    println(id)
    push!(qid, id)
  end
  return qid
end

# collect_id
function collect_id(id_list)
  # base url
  search_base ="http://crd.ndl.go.jp/reference/modules/d3ndlcrdsearch/index.php?page=detail_list&type=reference&mcmd=200&st=update&asc=desc&dtltbs=1&ndc_lk=1&ndc1="  
  # search result
  result_base = r"http://crd.ndl.go.jp/reference/modules/d3ndlcrdentry/index.php\?page=ref_view\&ldtl=1\&dtltbs=\d\&mcmd=200\&st=update\&asc=desc(?:|\&pg=\d+)\&ndc1=\d\&ndc_lk=1\&id=(\d+)"
  # NDC一次区分
  ndc_top = collect(0:9)
  qid = []
  # question id
  for ndc in ndc_top
    println(ndc)
    pg = 1
    while true
      println(search_base*"$ndc"*"&pg=$pg")
      html = readall(get(search_base*"$ndc"*"&pg=$pg"))
      qid, pg = id_parse(qid, html, result_base), pg + 1
      !contains(html, "&pg=$pg") && break
    end
  end
  gc()
  f = open(id_list, "w")
  write(f, join(qid, "\n"))
  close(f)
end

# レファレンス記録の取得&パース
function get_reference_question(id_list, page_dict)
  # 保存用
  !isdir("jp_reference") && mkdir("jp_reference")
  # 確認用
  if isfile(page_dict)
    d = open(deserialize, page_dict)
  else
    d = Dict()
  end 
  # base URL
  base = "http://crd.ndl.go.jp/reference/detail?page=ref_view&id="
  # レファレンス記録取得
  qid = unique(split(readall(id_list), "\n"))
  try
    for (i, id) in enumerate(qid)
      println(i,": ",id)
      haskey(d, id) && continue
      html = readall(get(base*"$id"))
      m = match(r"<div class=\"editorItem forceBreak\">(.+?)</div>", html)[1] 
      question = lstrip(replace(m, r"<.+?>|\n", ""))
      d[id] = [question, "jp_reference/$id.html"]
      println(question)
      write(open("jp_reference/$id.html", "w"), html)
      i % 100 == 0 && open(io -> serialize(io, d), page_dict, "w")
      sleep(rand()*0.9)
    end
  catch
    # エラーハンドリン
    println("error?")
　  open(io -> serialize(io, d), page_dict, "w")
    # 再送
    println("sleep ...")
    sleep(10)
    get_reference_question(id_list, page_dict)
  end　
end

# page_idを取得
id_list = "jp_reference_id.dat"
#collect_id(id_list)

# 記事取得
page_dict = "jp_reference_description.dict"
get_reference_question(id_list, page_dict)


