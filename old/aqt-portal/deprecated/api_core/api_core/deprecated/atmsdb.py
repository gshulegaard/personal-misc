"""
ATMS Interface:
Interface between web framework & ATMS database.
Returns Python dictionary.  Cornice formats the information into JSON.

Dependencies:
- pymssql

Author: Matthew Fay
Edited: Grant Hulegaard
"""

import pymssql
import settings
from datetime import *

##
## Helpers
##

# Encrypt a string with PowerLock algorithm.
def encrypt_string(string):

    decrypt_string = (
        ' !"' + 
        "#$%&'()*+,-./0123456789:;<=>?@ABC" + 
        "DEFGHIJKLMNOPQRSTUVWXYZ[\]^_`abcdefghijkl" + 
        "mnopqrstuvwxyz{|}~~"
    )

    encrypt_string = (
        "~~{[}u;Ce83KX%:VIm!|gs]_aL-QEOpx<UlzZjBq6" + 
        "#1($\\" + 
        '"FS5H0' + 
        "'" + 
        "cM&>Po.NGA*Jr)" + 
        "Y Dv/t9kd?^fni,hR2Wy=`+4T@7wb"
    )
    
    length = len(string)

    if 1 <= length and length <= 3:
        multiplier = 1
    elif 4 <= length and length <= 6:
        multiplier = 2
    elif 7 <= length and length <= 9:
        multiplier = 3
    else:
        multiplier = 4

    encrypted_string = ""

    for count in range(1, length + 1):
        offset = count * multiplier
        work = string[count - 1]
        position = (decrypt_string.index(work)) + 1
        position += offset
        position = position % 95
        work = encrypt_string[position + 1]
        encrypted_string += work
        if 1 <= multiplier and multiplier <= 3:
            multiplier += 1
        else:
            multiplier = 1

    return encrypted_string


#
# Interface Functions
#

# Authenticate user.
# Returns -1 if username/password is invalid.
def authenticate_user(username, password):
    # Initialize dictionary for return.
    response_data = {}

    # Check for AQT ByPass
    if username == 'admin' and password == 'AQTS':
        # Successful login
        response_data['result'] = '0'
        response_data['message'] = 'Successful login.'
        return response_data

    # Encrypt the plain text password, if it's not "changeme"
    if password != 'changeme':
        password = encrypt_string(password)

    # Connect to the SQL Server ATMS database
    try:
        conn = pymssql.connect(
            settings.atms_database_server, 
            settings.atms_database_user, 
            settings.atms_database_password, 
            settings.atms_database_name
        )
    except:
        response_data['result'] = '-1'
        response_data['message'] = 'Database connection failed.'
        return response_data

    # Create the cursor
    cursor = conn.cursor()

    ## See if the login is from the pl_usr table.  If not, check the
    ## st_emp_id1 or st_emp_id2 in the student table to see if it is
    ## there.  If so, attempt to link back to the pl_usr table with
    ## the opposite ID.

    # Boolean to keep track of whether we have a valid user or not
    validUser = False

    # Query the pl_usr table
    cursor.execute('select usr_login from pl_usr where usr_login=%s', username)

    # Grab first row from the cursor data.
    row = cursor.fetchone()

    if row is None:
        # Query the student table (st_emp_id2)
        cursor.execute('select st_emp_id2 from student where st_emp_id1=%s', username)
        # Grab first row from the cursor data.
        row = cursor.fetchone()
        if row is None:
            # Query the student table (st_emp_id1)
            cursor.execute('select st_emp_id1 from student where st_emp_id2=%s', username)
            # Grab first row from the cursor data.
            row = cursor.fetchone()
            if row is not None:
                validUser = True
                # Change username to st_emp_id1
                username = row[0]
        else:
            validUser = True
            # Change username to st_emp_id2
            username = row[0]
    else:
        validUser = True

    if validUser:
        # Get user status, user expire date, user password date, and whether
        # user must change password, all from the pl_usr table
        cursor.execute(
            'select usr_status, usr_expire_date, usr_pwd_date, usr_force_pswd_chg ' +
            'from pl_usr where usr_login=%s and usr_pwd=%s', (username, password)
        )

        # Grab first row from the cursor data.
        row = cursor.fetchone()
        
        if row is None:
            # We have a valid username, but the password is wrong.
            # Check the attempted logins against the grace logins to 
            # see if the login should be set to inactive.

            # Get the number of incorrect logins allowed.
            cursor.execute('select app_grace from pl_app where app_key=1')
            # Grab first row from the cursor data.
            row = cursor.fetchone()
            # Set grace attempts value
            graceAttempts = row[0]
            # Check to see if grace attempts are turned on.
            if graceAttempts > 0:
                # Get the number of incorrect logins for this user.
                cursor.execute('select usr_login_attempts from pl_usr where usr_login=%s', username)
                # Grab first row from the cursor data.
                row = cursor.fetchone()
                # Increment
                loginAttempts = row[0] + 1
                # Check if we need to set login inactive
                if graceAttempts < loginAttempts:
                    # We do.
                    cursor.execute('update pl_usr set usr_status=0 where usr_login=%s', username)
                    # Commit data
                    conn.commit()
                    # Close database connection
                    conn.close()
                    # Return back appropriate message
                    response_data['result'] = '-2'
                    response_data['message'] = 'Inactive login.'
                    return response_data
                else:
                    # Increase user login attempts.
                    cursor.execute('update pl_usr set usr_login_attempts=%d where usr_login=%s', (loginAttempts, username))
                    # Commit data
                    conn.commit()
                    # Close database connection
                    conn.close()
                    # Return back appropriate message
                    response_data['result'] = '-3'
                    response_data['message'] = 'Invalid login.'
                    return response_data
        else:
            userStatus = row[0]
            userExpireDate = row[1]
            # The date that the user's password was last changed.
            userPasswordDate = row[2]
            userForcePasswordChange = row[3]

    if not validUser:
        # Close database connection
        conn.close()
        # Return back appropriate message
        response_data['result'] = '-3'
        response_data['message'] = 'Invalid login.'
        return response_data

    ## If we get here, the user has been successfully authenticated.

    # Get the User ID and Name.
    cursor.execute('select usr_key, usr_name from pl_usr where usr_login=%s', username)
    # Grab first row from the cursor data.
    row = cursor.fetchone()
    # Set the variables
    userID = row[0]
    userFullName = row[1]

    # Determine if the user is an active student.
    cursor.execute(
        'select st_student_id from pl_usr, student where ' +
        'pl_usr.usr_key=%d and ' +
        '(pl_usr.usr_login = student.st_emp_id1 or pl_usr.usr_login = student.st_emp_id2) ' +
        'and student.sycd_st_status = 28', userID
    )
    # Grab first row from the cursor data.
    row = cursor.fetchone()
    if row is not None:
        userIsStudent = True
        studentID = row[0]
    else:
        userIsStudent = False

    # Determine if the user is an active instructor.
    cursor.execute(
        'select count(*) from student, student_position, position ' +
        'where (student.st_emp_id1 = %s or student.st_emp_id2 = %s) ' +
        'and student.sycd_st_status = 28 ' +
        'and student.st_student_id = student_position.st_student_id ' +
        'and student_position.po_position_id = position.po_position_id ' +
        'and student_position.sycd_po_status = 39 ' +
        'and student_position.stpo_eff_date <= GETDATE() ' +
        'and position.po_instructor_ind = %s',
        (username, username, 'Y')
    )
    # Grab first row from the cursor data.
    row = cursor.fetchone()
    if row is None:
        # Query
        cursor.execute(
            'select count(*) from pl_usr, student ' +
            'where pl_usr.usr_key = %d ' +
            'and (pl_usr.usr_login = student.st_emp_id1 OR pl_usr.usr_login = student.st_emp_id2) ' +
            'and student.sycd_st_status = 28 ' +
            'and student.st_ext_instr_ind = %s'
            (userID, 'Y')
        )
        if row is None:
            userIsInstructor = False
        else:
            userIsInstructor = True
    else:
        userIsInstructor = True

    # Check to see if the login is active.
    if userStatus == 0:
        # Inactive.
        # Close database connection
        conn.close()
        # Return back appropriate message
        response_data['result'] = '-2'
        response_data['message'] = 'Inactive login.'
        return response_data

    # Check to see if the login has previously expired.
    if userStatus == 2:
        # Expired.
        # Close database connection
        conn.close()
        # Return back appropriate message
        response_data['result'] = '-4'
        response_data['message'] = 'Expired login.'
        return response_data

    # Calculate whether the login and password are currently expired.

    # Get current datetime.
    now = datetime.now()

    if userExpireDate != '' and userExpireDate is not None:
        if userExpireDate <= str(now):
            # Expire the login.
            cursor.execute('update pl_usr set usr_status=2 where usr_login=%s and usr_pwd=%s', (username, password))
            # Commit data
            conn.commit()
            # Close database connection
            conn.close()
            # Return back appropriate message
            response_data['result'] = '-4'
            response_data['message'] = 'Expired login.'
            return response_data

    if userPasswordDate != '' and userPasswordDate is not None:
        # Get the number of days until a password expires.
        cursor.execute('select app_pwd_days from pl_app where app_key=1')
        # Grab first row from the cursor data.
        row = cursor.fetchone()
        if row is not None and row[0] > 0:
            numberOfDaysUntilPwdExpires = row[0]
            # Convert userPasswordDate to a python datetime object,
            # so that we can increment it.
            userPasswordDate = datetime.strptime(userPasswordDate, '%Y%m%d')
            # Calculate the date at which the user's password expires.
            userPasswordDate += timedelta(days=numberOfDaysUntilPwdExpires)
            if userPasswordDate <= now:
                # User's password is expired. They have to change it.
                # Close database connection
                conn.close()
                # Return back appropriate message
                response_data['result'] = '-5'
                response_data['message'] = 'Expired password.'
                return response_data

    # Check to see if the existing password is "changeme" or the
    # force password change flag is set.
    if password == 'changeme' or userForcePasswordChange == 'Y':
        # Close database connection
        conn.close()
        # Return back appropriate message
        response_data['result'] = '-6'
        response_data['message'] = 'User must change password.'
        return response_data

    # Set user login attempts to 0.
    cursor.execute('update pl_usr set usr_login_attempts=0 where usr_login=%s', username)
    # Commit data
    conn.commit()
    # Close database connection
    conn.close()
    # Return back success
    response_data['result'] = '0'
    response_data['message'] = 'Success'
    return response_data

# Get application access data for a specific user (what they can launch).
def get_app_access(username, password):
    # List of applications
    application_list = []

    # Initialize dictionary for return.
    response_data = {}

    # Check for AQT ByPass
    if username == 'admin' and password == 'AQTS':
        # Grant access to all applications
        response_data['result'] = '0'
        response_data['message'] = [1, 2, 3, 4]
        return response_data

    # Connect to the SQL Server ATMS database
    try:
        conn = pymssql.connect(
            settings.atms_database_server, 
            settings.atms_database_user, 
            settings.atms_database_password, 
            settings.atms_database_name
        )
    except:
        response_data['result'] = '-1'
        response_data['message'] = 'Database connection failed.'
        return response_data
    
    # Create the cursor
    cursor = conn.cursor()

    # Get the list of applications that the user can access
    cursor.execute('select distinct app_key from pl_app_grp where grp_key in ' + 
                   '(select grp_key from pl_grp_usr where usr_key=' +
                   '(select usr_key from pl_usr where usr_login=%s))', username)

    # Iterate
    for row in cursor:
        application_list.append(row[0])
    
    # Close the connection
    conn.close()

    # Build return dictionary
    response_data['result'] = '0'
    response_data['message'] = application_list

    return response_data


# Return the ToDo list for a student, based on st_student_id
def get_todo_list(st_student_id):
    return 1
