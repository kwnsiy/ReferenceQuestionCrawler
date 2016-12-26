# coding:utf-8

doc=
"""
  レファレンス質問収集プログラム
  QuestionPoint KnowledgeBaseより
"""

using DataFrames
using Requests

base = "http://questionpoint.org/crs/servlet/org.oclc.kb.KBSearchWS?andk="
page = "https://www.lib.montana.edu/~jason/files/question-point/answer.php?id="

query = ["From+Chat+Session", "From+Chat+Transcript"]
qid = []

# question id
for q in query
  xml = readall(get(base*q))
  for m in matchall(r"<id>(.+?)</id>", xml)
    println(m[5:end-5])
    push!(qid, m[5:end-5])
  end
end

# unique
qid = unique(qid)

# question
question = []
for (i, id) in enumerate(qid) 
  println(i)
  html = readall(get(page*id))
  m = match(r"<dt><strong>(.+?)</strong></dt>", replace(html, r"\n|\r", ""))[1]
  rq = replace(m, r"<.+?>|^\[.+?\](?::|)\s*|^Chat Session Transcript.\s*", "")
  println(rq)
  push!(question, rq)
end

# save
df = DataFrame(qid = qid, question = question)
writetable("reference_question_en.dat", df, separator = '\t', header = true)


