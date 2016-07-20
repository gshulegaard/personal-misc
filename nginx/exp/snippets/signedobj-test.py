# -*- coding: utf-8 -*-
from hamcrest import *

from test.base import BaseTestCase

from naas.core.object import SignedObject, SignatureException


__author__ = "Grant Hulegaard"
__copyright__ = "Copyright (C) 2015, Nginx Inc. All rights reserved."
__credits__ = ["Mike Belov", "Andrei Belov", "Ivan Poluyanov", "Oleg Mamontov", "Andrew Alexeev", "Grant Hulegaard"]
__license__ = ""
__maintainer__ = "Grant Hulegaard"
__email__ = "grant.hulegaard@nginx.com"


class SignedObjectTestCase(BaseTestCase):
    def test_basic(self):
        obj = SignedObject(name='foo', description='bar')
        assert_that(obj, is_not(None))

        assert_that(obj, not_(has_property('name')))
        assert_that(obj, not_(has_property('description')))
        assert_that(obj.attributes, is_(set))
        assert_that(obj.attributes, equal_to(set()))
        assert_that(obj.to_dict(), equal_to({}))

    def test_basic_force(self):
        obj = SignedObject(name='foo', description='bar', _force=True)
        assert_that(obj, is_not(None))

        assert_that(obj, has_properties(dict(name='foo', description='bar')))
        assert_that(obj.attributes, is_(set))
        assert_that(obj.attributes, has_items('name', 'description'))
        assert_that(obj.to_dict(), equal_to({
            'name': 'foo',
            'description': 'bar'
        }))

    def test_setattr(self):
        obj = SignedObject(name='foo', description='bar')

        assert_that(obj.attributes, is_(set()))
        assert_that(obj.attributes, equal_to(set([])))

        assert_that(calling(obj.__setattr__).with_args('name', 'foo'), raises(SignatureException))

        obj = SignedObject(name='foo', description='bar', _force=True)
        obj.name='foo2'

        assert_that(obj.name, equal_to('foo2'))
        assert_that(obj.to_dict(), equal_to({
            'name': 'foo2',
            'description': 'bar'
        }))

    def test_inheritance(self):
        class TestSigned(SignedObject):
            def __init__(self, **kwargs):
                self._signature = set(['name'])
                super(TestSigned, self).__init__(**kwargs)

        obj = TestSigned()
        assert_that(obj, is_not(None))
        assert_that(obj.attributes, equal_to(set(['name'])))
        assert_that(obj.name, equal_to(None))

        obj.name = 'foo'
        assert_that(obj.name, equal_to('foo'))

        assert_that(obj.to_dict(), equal_to({
            'name': 'foo'
        }))
