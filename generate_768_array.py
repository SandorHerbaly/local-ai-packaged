# Generáljunk egy 768 elemű tömböt
values = [round(0.1 * (i % 10), 1) for i in range(768)]
sql_array = ', '.join(map(str, values))

# Generáljuk az SQL utasítást
sql_query = f"""
INSERT INTO n8n_vectors_table (text, metadata, embedding)
VALUES (
    'Sample text',
    '{{"source": "test"}}',
    ARRAY[{sql_array}]
);
"""

# Másold ki és futtasd az eredményt PostgreSQL-ben
print(sql_query)
