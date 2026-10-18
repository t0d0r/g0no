# Word-level diff for the history view. Returns runs like
# [[:same, "Milk, "], [:del, "bread"], [:ins, "butter"]].
module TextDiff
  # Longest-common-subsequence table limit (cells) after trimming the common
  # start and end; beyond it the whole middle is shown as replaced.
  MAX_CELLS = 400_000

  module_function

  def diff(old_text, new_text)
    a = tokenize(old_text)
    b = tokenize(new_text)

    prefix = 0
    prefix += 1 while prefix < a.size && prefix < b.size && a[prefix] == b[prefix]
    suffix = 0
    suffix += 1 while suffix < a.size - prefix && suffix < b.size - prefix && a[-1 - suffix] == b[-1 - suffix]

    middle_a = a[prefix...(a.size - suffix)]
    middle_b = b[prefix...(b.size - suffix)]
    ops = a.first(prefix).map { |token| [ :same, token ] }
    ops.concat(middle_ops(middle_a, middle_b))
    ops.concat(a.last(suffix).map { |token| [ :same, token ] })
    merge(ops)
  end

  def tokenize(text)
    text.to_s.scan(/\s+|[^\s]+/)
  end

  def middle_ops(a, b)
    return b.map { |token| [ :ins, token ] } if a.empty?
    return a.map { |token| [ :del, token ] } if b.empty?
    return [ [ :del, a.join ], [ :ins, b.join ] ] if a.size * b.size > MAX_CELLS

    # lengths[i][j] = LCS length of a[i..] and b[j..]
    lengths = Array.new(a.size + 1) { Array.new(b.size + 1, 0) }
    (a.size - 1).downto(0) do |i|
      (b.size - 1).downto(0) do |j|
        lengths[i][j] = a[i] == b[j] ? lengths[i + 1][j + 1] + 1 : [ lengths[i + 1][j], lengths[i][j + 1] ].max
      end
    end

    ops = []
    i = j = 0
    while i < a.size && j < b.size
      if a[i] == b[j]
        ops << [ :same, a[i] ]
        i += 1
        j += 1
      elsif lengths[i + 1][j] >= lengths[i][j + 1]
        ops << [ :del, a[i] ]
        i += 1
      else
        ops << [ :ins, b[j] ]
        j += 1
      end
    end
    ops.concat(a[i..].map { |token| [ :del, token ] })
    ops.concat(b[j..].map { |token| [ :ins, token ] })
  end

  def merge(ops)
    ops.each_with_object([]) do |(kind, text), runs|
      if runs.last && runs.last[0] == kind
        runs.last[1] += text
      else
        runs << [ kind, +text ]
      end
    end
  end
end
