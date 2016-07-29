# -*- coding: utf-8 -*-
import os
import sys
import subprocess

from optparse import OptionParser, Option
from pudb import set_trace

sys.path.insert(0, os.getcwd())  # to make naas libs available

from naas.common.context import context
from naas.common.util.loader import import_module, import_class
from naas.common.util import logger


__author__ = "Grant Hulegaard"
__copyright__ = "Copyright (C) Nginx, Inc. All rights reserved."
__credits__ = ["Mike Belov", "Andrei Belov", "Ivan Poluyanov", "Oleg Mamontov", "Andrew Alexeev", "Grant Hulegaard", "Arie van Luttikhuizen"]
__license__ = ""
__maintainer__ = "Grant Hulegaard"
__email__ = "grant.hulegaard@nginx.com"


app_config = import_class('tests.config.app.TestingConfig')()
logger_config = import_class('tests.config.logger.TestingConfig')()

context.setup(app='test', app_config=app_config, logger_config=logger_config)
# context.access_log = context.default_log
# context.body_log = context.default_log
# context.error_log = context.default_log
# context.requests_log = context.default_log
context.access_log = logger.get('devnull')
context.body_log = logger.get('devnull')
context.error_log = logger.get('devnull')
context.requests_log = logger.get('devnull')


def shell_call(cmd, output=False):
    print '\n\033[32m%s\033[0m' % cmd
    if output:
        result = subprocess.check_output(shlex.split(cmd))
        print result
        return result
    else:
        os.system(cmd)


def py_test_path_parser(path):
    filepath, class_name, method_name = path.split('::')
    module = filepath.replace('.py', '')
    module = module.replace('/', '.')
    return module, class_name, method_name


usage = "usage: python %prog -h"

option_list = (
    Option(
        '-p', '--path',
        action='store',
        dest='path',
        type='string',
        help='py.test path to debug',
    ),
)

parser = OptionParser(usage, option_list=option_list)
options, args = parser.parse_args()


if __name__ == '__main__':
    if not options.path:
        parser.print_help()
        sys.exit(1)

    module, class_name, method_name = py_test_path_parser(options.path)

    module = import_module(module)
    obj = getattr(module, class_name)(methodName=method_name)
    obj.setup_method(getattr(obj, method_name))

    set_trace()
    obj.run()
