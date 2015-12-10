"""
Guacamole MySQL interface:

This library provides a series of functions for interfacing with the Guacamole
0.9.5 MySQL Auth module.  Functions will insert values into the MySQL database
and return basic information to Cornice for passing back through the RESTful web
service.

For context, we are inserting temporary user records for use by the EmberJS
front-end that should be removed on log out/session termination.  To this end
there are three stages to the life cycle of this interface:

  1) Insert temporary user record.
  2) Insert required connections on demand.
  3) Remove user record and generated connections.

The implicit assumption for stage 3 is that connections have 1-to-1
assignment with users.  That is, a connection will only be assigned to one user
at any given time.  In the rewrite by Grant Hulegaard, the remove_connections()
function was made robust enough to handle situations where a connection has been
assigned to multiple users, but it is still recommended policy to not share
connections between users using this interface.

Dependencies:
  - pymysql (https://www.python.org/dev/peps/pep-0249/#cursor-methods)
  - configobj (http://www.voidspace.org.uk/python/configobj.html#getting-started)

Author: Grant Hulegaard

Based on original "guacdb.py" written by Matthew Fay.
"""

from configobj import ConfigObj
import pymysql

# Import settings.ini that lives in the same directory as this script.
config = ConfigObj('settings.ini')


## Functions


def insert_user(username, password):
    """
    Insert a temporary user record into the Guacamole MySQL database.
    """

    response = {}

    # Open a connection to the database.
    try:
        conn = pymysql.connect(
            host = config['web-database']['server'],
            port = 3306, # Default MySQL port.
            user = config['web-database']['user'],
            passwd = config['web-database']['pass'],
            db = config['web-database']['name']
        )
    except:
        # Break processing and return error.
        response['status'] = '-1'
        response['message'] = 'Database connection failed.'
        return response

    cur = conn.cursor()

    # Check to see if user record already exists.
    cur.execute(
        ('SELECT user_id ' 
         'FROM guacamole_user '
         'WHERE username=%s'),
        username
    )

    row = cur.fetchone()
    # cur.fetchone() returns 'None' if the query returned no data.

    # If there is a user record...
    if row is not None:
        # Create success response and send it to Cornice.
        conn.close()
        response['status'] = '0'
        response['message'] = 'User record already exists.'
        return response

    # If there is no user record...
    else:
        # Generate SALT variable in MySQL
        cur.execute("SET @salt = UNHEX(SHA2(UUID(), 256))")

        # Insert Guac user record
        try:
            cur.execute(
                ('INSERT INTO guacamole_user '
                 '(username, password_salt, password_hash) '
                 'VALUES (%s, @salt, UNHEX(SHA2(CONCAT(%s, HEX(@salt)), 256)))'),
                (username, password)
            )
        except:
            # Break processing and return error.
            conn.close()
            response['status'] = '-1'
            response['message'] = ('Database error while inserting Guac user '
                                   'record.')
            return response

        # Create success response and send it to Cornice.
        conn.commit()
        conn.close()
        response['status'] = '0'
        response['message'] = 'User record was created.'
        return response


def insert_connection(connection_tag, app, username, password):
    """
    Insert new guacamole connection information into the MySQL database.
    """

    response = {}

    # Open a connection to the database.
    try:
        conn = pymysql.connect(
            host = config['web-database']['server'],
            port = 3306, # Default MySQL port.
            user = config['web-database']['user'],
            passwd = config['web-database']['pass'],
            db = config['web-database']['name']
        )
    except:
        # Break processing and return error.
        response['status'] = '-1'
        response['message'] = 'Database connection failed.'
        return response

    cur = conn.cursor()

    # Insert parent connection record.
    try:
        cur.execute(('INSERT INTO guacamole_connection (connection_name, protocol) '
                     'VALUES (%s, %s)'),
                    (connection_tag, 'rdp')
                )
    except:
        # Break processing and return error.
        conn.close()
        response['status'] = '-1'
        response['message'] = ('Database error while inserting the parent '
                               'connection into the MySQL database.')
        return response

    # Set the MySQL connection_id variable.
    cur.execute('SET @connection_id = LAST_INSERT_ID()')

    # Store the connection_id in our response.
    cur.execute('SELECT @connection_id')

    row = cur.fetchone()
    response['connection_id'] = row[0]

    # Now that we have a parent connection record, we need to insert the
    # connection parameters into 'guacamole_connection_parameter'.  These
    # parameters depend on our settings in the settings.ini file.

    # Insert the global connection parameters.
    try:
        # Hostname
        cur.execute(('INSERT INTO guacamole_connection_parameter '
                     'VALUES (@connection_id, %s, %s)'),
                    ('hostname', config['webrdp']['server'])
        )

        # Username
        cur.execute(('INSERT INTO guacamole_connection_parameter '
                     'VALUES (@connection_id, %s, %s)'),
                    ('username', config['webrdp']['user'])
        )

        # Password
        cur.execute(('INSERT INTO guacamole_connection_parameter '
                     'VALUES (@connection_id, %s, %s)'),
                    ('password', config['webrdp']['pass'])
        )

        # Domain
        cur.execute(('INSERT INTO guacamole_connection_parameter '
                     'VALUES (@connection_id, %s, %s)'),
                    ('domain', config['webrdp']['domain'])
        )

        # Enable printing
        cur.execute(('INSERT INTO guacamole_connection_parameter '
                     'VALUES (@connection_id, %s, %s)'),
                    ('enable-printing', config['webrdp']['enable_printing'])
        )

        # Enable drive
        cur.execute(('INSERT INTO guacamole_connection_parameter '
                     'VALUES (@connection_id, %s, %s)'),
                    ('enable-drive', config['webrdp']['enable_drive'])
        )

        # Drive path
        cur.execute(('INSERT INTO guacamole_connection_parameter '
                     'VALUES (@connection_id, %s, %s)'),
                    ('drive-path', config['webrdp']['drive_path'])
        )

    except:
        # Break processing and return error.
        conn.close()
        response['status'] = '-1'
        response['message'] = ('Database error while inserting the global '
                               'connection parameters.')
        return response

    # Check to see if you can find the 'app' in the settings.ini.
    try:
        tmp = config['webrdp'][app]

    except:
        # Break processing and return error.
        conn.close()
        response['status'] = '-1'
        response['message'] = ('Could not find specified application in '
                               'settings.ini.')
        return response

    # Insert app specific parameters.
    try:
        # Remote app
        cur.execute(('INSERT INTO guacamole_connection_parameter '
                     'VALUES (@connection_id, %s, %s)'),
                    ('remote-app', config['webrdp'][app]['alias'])
        )

    except:
        # Break processing and return error.
        conn.close()
        response['status'] = '-1'
        response['message'] = ('Database error while inserting the application '
                               'connection parameters.')
        return response

    # Create RemoteApp command line argument string.
    connection_string = ('connection=' + config['atmsapi']['connection'] + 
                         ' login=' + username + '/' + password + 
                         ' webrdp')

    # Insert the argument string into guacamole_connection_parameter.
    try:
        # Remote app args
        cur.execute(('INSERT INTO guacamole_connection_parameter '
                     'VALUES (@connection_id, %s, %s)'),
                    ('remote-app-args', connection_string)
        )
    except:
        # Break processing and return error.
        conn.close()
        response['status'] = '-1'
        response['message'] = ('Database error while inserting the remote application '
                               'arguments string as a parameter.')
        return response

    # Commit changes.
    conn.commit()
    conn.close()

    # Generate success message and return it.
    response['status'] = '0'
    response['message'] = 'Connection was created.'
    # Remember that the response also has a 'connection_id' value that was set earlier.

    return response


def assign_user(username, connection_id):
    """
    Link a connection to a user record in the 'guacamole_connection_permission'
    table.
    """

    response = {}

    # Open a connection to the database.
    try:
        conn = pymysql.connect(
            host = config['web-database']['server'],
            port = 3306, # Default MySQL port.
            user = config['web-database']['user'],
            passwd = config['web-database']['pass'],
            db = config['web-database']['name']
        )
    except:
        # Break processing and return error.
        response['status'] = '-1'
        response['message'] = 'Database connection failed.'
        return response

    cur = conn.cursor()

    # Get and set the user_id.
    cur.execute(
        ('SET @user_id = '
         '(SELECT user_id '
         'FROM guacamole_user '
         'WHERE username=%s)'), 
        username
    )

    # Set the connection_id.
    cur.execute(
        ('SET @connection_id = %s'),
        connection_id
    )

    # Link the connection to the user record.
    try:
        cur.execute(
            ('INSERT INTO guacamole_connection_permission '
             'VALUES (@user_id, @connection_id, %s)'),
            'READ'
        )

    except:
        # Break processing and return error.
        conn.close()
        response['status'] = '-1'
        response['message'] = 'Linking connection with user record failed.'
        return response

    # Commit changes.
    conn.commit()
    conn.close()

    # Generate success message and return it.
    response['status'] = '0'
    response['message'] = 'Link between connection and user was successful.'

    return response


def remove_connections(username):
    """
    Remove connections assigned to a user.
    """

    response = {}

    # Open a connection to the database.
    try:
        conn = pymysql.connect(
            host = config['web-database']['server'],
            port = 3306, # Default MySQL port.
            user = config['web-database']['user'],
            passwd = config['web-database']['pass'],
            db = config['web-database']['name']
        )
    except:
        # Break processing and return error.
        response['status'] = '-1'
        response['message'] = 'Database connection failed.'
        return response

    cur = conn.cursor()

    # Get and set the user_id.
    cur.execute(
        ('SET @user_id = '
         '(SELECT user_id '
         'FROM guacamole_user '
         'WHERE username=%s)'), 
        username
    )

    # Get connection_id's that are attached to the user.
    cur.execute(
        ('SELECT connection_id '
         'FROM guacamole_connection_permission '
         'WHERE user_id=@user_id')
    )

    connection_ids = cur.fetchall()

    # Now that we have the connection_ids, iterate over them to remove all
    # connection information from: guacamole_connection_permission,
    # guacamole_connection_parameter, and guacamole_connection.

    for connection in connection_ids:
        # Remove connection-user link.
        try:
            cur.execute(
                ('DELETE FROM guacamole_connection_permission '
                 'WHERE connection_id=%s'),
                connection
            )
        except:
            # Break processing and return error.
            conn.close()
            response['status'] = '-1'
            response['message'] = ('Error deleting user link for connection #' +
                                   connection)
            return response

        # Remove connection parameters
        try:
            cur.execute(
                ('DELETE FROM guacamole_connection_parameter '
                 'WHERE connection_id=%s'),
                connection
            )
        except:
            # Break processing and return error.
            conn.close()
            response['status'] = '-1'
            response['message'] = ('Error deleting parameters for connection #' +
                                   connection)
            return response

        # Remove parent connection
        try:
            cur.execute(
                ('DELETE FROM guacamole_connection '
                 'WHERE connection_id=%s'),
                connection
            )
        except:
            # Break processing and return error.
            conn.close()
            response['status'] = '-1'
            response['message'] = ('Error deleting parent connection #' + connection)
            return response

    # At this point, all connections assigned to the user should be removed.

    # Commit changes.
    conn.commit()
    conn.close()

    # Generate success message and return it.
    response['status'] = '0'
    response['message'] = 'All user connections have been removed.'    

    return response


def remove_user(username):
    """
    Remove user record from Guacamole.

    WARNING: This should not be run without first removing connections assigned
    to the user with remove_connections().
    """

    response = {}

    # Open a connection to the database.
    try:
        conn = pymysql.connect(
            host = config['web-database']['server'],
            port = 3306, # Default MySQL port.
            user = config['web-database']['user'],
            passwd = config['web-database']['pass'],
            db = config['web-database']['name']
        )
    except:
        # Break processing and return error.
        response['status'] = '-1'
        response['message'] = 'Database connection failed.'
        return response

    cur = conn.cursor()

    # Get and set the user_id.
    cur.execute(
        ('SET @user_id = '
         '(SELECT user_id '
         'FROM guacamole_user '
         'WHERE username=%s)'), 
        username
    )

    # Remove the user.
    try:
        cur.execute(
            ('DELETE FROM guacamole_user '
             'WHERE user_id=@user_id')
        )
    except:
        # Break processing and return error.
        conn.close()
        response['status'] = '-1'
        response['message'] = 'Error deleting user record.'
        return response

    # Commit changes.
    conn.commit()
    conn.close()

    # Generate success message and return it.
    response['status'] = '0'
    response['message'] = 'User has been deleted.'

    return response
