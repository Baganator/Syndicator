#!/usr/bin/python3
import csv

all_items = []
seen_items = {}

with open('ItemExtendedCost.csv', newline='') as f:
    reader = csv.DictReader(f, delimiter=',')
    for row in reader:
        for index in range(0, 5):
            item_id = row['ItemID_' + str(index)]
            if item_id != "0" and item_id not in seen_items:
                all_items.append(item_id)
                seen_items[item_id] = True

data_format = """\
  [{}] = true,\
"""

all_items.sort()

print("Syndicator.Data.CurrencyItems = {")
for item_id in all_items:
    print(data_format.format(item_id))
print("}")
