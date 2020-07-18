import sys, csv

def usage(opt_msg=''):
    if opt_msg:
        print(opt_msg)
        print('')
    print("this scripts takes a csv-file and creates an import.sql file which could be used to generate INSERT INTO SQL statements from a csv-file.")
    print('usage my-csv-to-sql -f <csv_file> -n <table_name> -t <table_schema -o <output_file>')
    print(' -f <csv_file> a csv file in UTF-8 as exported from excel')
    print(' -n <table_name> name of the SQL table in the database to create the INSERT INTO statements')
    print(' -t <table_schema> optional colon sperated list of columns. e.g. ScenarioID,Defect_ID,ME_Type,EME_id. if not provided first row of the given csv-file will be used')
    print(' -o <output_file> sql file where the final INSERT statement shall be written')
    print(' --nullvalue <null_value> optional place-holder value in the csv_file which will be replaced by null in the insert statements. "null" by default.')
    sys.exit(2)

def readArguments(argv):
    csv_file = ""
    table_schema = ""
    table_name = ""
    output_file = ""
    null_value = "null"

    while len(argv) > 0:
        opt = argv.pop(0)
        if opt == "-h":
            usage()
            sys.exit(2)
        elif opt == "-f":   
            csv_file = argv.pop(0)
        elif opt == "-t":
            table_schema = argv.pop(0)
        elif opt == "-n":
            table_name = argv.pop(0)
        elif opt == "-o":
            output_file = argv.pop(0)
        elif opt == "--nullvalue":
            null_value = argv.pop(0)
        else:
            usage('unrecogniced option {}'.format(opt))
    
    if not csv_file:   
        usage("-f missing - no csv_file given")   

    if not table_name:   
        usage("-n missing - no table_name given")   

    if not output_file:   
        usage("-o missing - no output_file given")   

    return {"csv_file": csv_file, "table_name": table_name, "table_schema": table_schema, "output_file": output_file, "null_value": null_value}


# return a list of dictionaries from the given csv-file
# if the tabel_schema is not given the first row of the csv file will be used
def readCSV(csv_file, table_schema=''):
    #according to the docs of the csv module it should be opened with newline=''
    with open(csv_file, newline='', encoding="utf-8-sig") as open_csv_file:
        csv_reader = None
        # read csv with or without a given "schema" to a dictionary
        if not table_schema:
            csv_reader = csv.DictReader(open_csv_file, delimiter=';')
        else:
            csv_reader = csv.DictReader(open_csv_file, delimiter=';', fieldnames=table_schema.split(","))
        return list(csv_reader)

def createInsertStatement(parsed_csv, table_name, null_value):
    # getting the key to have access to the "schema"
    table_columns = parsed_csv[0].keys();
    # joining all the table column name strings to a SQL style format
    table_columns_sql_formatted = ", ".join(table_columns)
    sql = "INSERT INTO {} ({})\nVALUES".format(table_name, table_columns_sql_formatted)
    for row in parsed_csv_list:
        sql += "\n ("
        for column in table_columns:
            # check whether a col should be mapped to a SQL-Null or not
            if row[column] == null_value:
                sql += "NULL,"
            else:
                sql += "'" + row[column].replace("'", "''") + "',"
        sql = sql[:-1]+")," #replacing last , by a ),
    sql = sql[:-1] + ";" #replace last, by a ;
    return sql   

def writeSQLStringToFile(sqlString, output_file):
    try:
        with open(output_file, "x") as sql_file:
            sql_file.write(sqlString)
    except FileExistsError:
        print("The given output_file {} already exists".format(output_file))
        usage()

#entry point of the application - "main"
if __name__ == "__main__":
    #copying args to ensure original argument list does not change while processing 
    relevant_args = sys.argv[:]
    relevant_args.pop(0) #cleaning the arguments because first one is not necessary needed
    arg_dict = readArguments(relevant_args)
    parsed_csv_list = readCSV(arg_dict["csv_file"], arg_dict['table_schema'])
    sqlStatement = createInsertStatement(parsed_csv_list, arg_dict["table_name"], arg_dict["null_value"])
    writeSQLStringToFile(sqlStatement, arg_dict["output_file"])
