"""
This file contains the primary application definition.
"""

import os
from flask import Flask


app = Flask(__name__,
            template_folder='templates')

if __name__ == '__main__':
    # Reinitialize application with debug settings.
    app = Flask(__name__,
                static_folder='../static',
                template_folder='templates')

    # Turn on DEBUG
    app.debug = True


@app.route('/')
def hello_world():
    return "Hello World2!"
    

if __name__ == '__main__':
    # Start development server
    app.run()
