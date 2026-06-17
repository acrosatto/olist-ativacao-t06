# Lê o arquivo SQL
with open('RFV.sql', 'r') as f:
    query = f.read()

# Define a data e substitui o placeholder
date = '2018-07-01'
query = query.format(date=date)

# Roda a query
df = spark.sql(query)

# Verifica resultado
print(f"Total de sellers: {df.count()}")
df.display()

