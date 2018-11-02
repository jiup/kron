class Revisions
  attr_accessor :current, :heads, :root, :rev_map # :tips,  # a map<branch_name, revision_head>
end