import csv
import string
import random

def loadCSV(filename):

    with open(filename) as csv_data:
        data = list(csv.reader(csv_data))

    data = data[5:]
    return data

models = loadCSV("car-models.csv")

plates = set()

for i in range(1000):
    letters = random.sample(string.ascii_uppercase, 4)
    num = random.randint(0, 999)
    plate = '{}{}{:03d}{}{}'.format(letters[0], letters[1], num, letters[2], letters[3])
    plates.add(plate)

f = open('fill_prod.sql', "w")
f.write("USE vehiclesapp_prod;\n")
for plate in plates:
    model = random.choice(models)
    name = model[0] + " " + model[1]
    name = name.replace("'", "")
    year = random.randint(1950, 2021)

    f.write("INSERT INTO vehicle(license_plate, vehicle_type, model, production_year) VALUES ('{}', 'car', '{}', '{}');\n".format(plate, name, year))
    fuel = random.randint(0, 100)
    mileage = random.randint(0, 300000)
    speed = random.randint(10, 150)
    f.write("INSERT INTO current_status(id, fuel, mileage, current_speed) VALUES ('{}', '{:d}', '{:d}', '{:d}');\n".format(plate, fuel, mileage, speed))
f.close()

f = open('fill_develop.sql', "w")
f.write("USE vehiclesapp_develop;\n")
for plate in plates:
    model = random.choice(models)
    name = model[0] + " " + model[1]
    name = name.replace("'", "")
    year = random.randint(1950, 2021)

    f.write("INSERT INTO vehicle(license_plate, vehicle_type, model, production_year) VALUES ('{}', 'car', '{}', '{}');\n".format(plate, name, year))
    fuel = random.randint(0, 100)
    mileage = random.randint(0, 300000)
    speed = random.randint(10, 150)
    f.write("INSERT INTO current_status(id, fuel, mileage, current_speed) VALUES ('{}', '{:d}', '{:d}', '{:d}');\n".format(plate, fuel, mileage, speed))

f.close()