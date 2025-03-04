
" Highlight SQL keywords inside triple-quoted strings in Python files
syntax region sqlString start=/'''\|"""/ end=/'''\|"""/ contains=sqlKeywords

" Define SQL keywords to highlight (Databricks specific)
syntax keyword sqlKeywords SELECT INSERT UPDATE DELETE FROM WHERE JOIN ON AS GROUP BY ORDER BY LIMIT CREATE DROP ALTER TABLE VIEW WITH AS USING UNION INTERSECT EXCEPT LEFT RIGHT FULL OUTER CROSS JOIN INNER JOIN AND OR IN OVER PARTITION BY ROLLUP SUM MAX MIN COUNT AVG EXPLODE GET

" Set the highlight group for SQL keywords
highlight link sqlKeywords Keyword

