# -*- coding: utf-8 -*-


__author__ = "Grant Hulegaard"
__copyright__ = "Copyright (C) 2015, Nginx Inc. All rights reserved."
__credits__ = ["Mike Belov", "Andrei Belov", "Ivan Poluyanov", "Oleg Mamontov", "Andrew Alexeev", "Grant Hulegaard"]
__license__ = ""
__maintainer__ = "Grant Hulegaard"
__email__ = "grant.hulegaard@nginx.com"


class SignatureException(Exception):
    MESSAGE_TEMPLATE = '"%s" key missing from object attribute signature (%s)'

    def __init__(self, context=tuple(), signature=list()):
        super(SignatureException, self).__init__()

        self.context = context
        self.signature = signature
        self.message = self.MESSAGE_TEMPLATE % (self.context[0], self.signature)

    def __repr__(self):
        return self.MESSAGE_TEMPLATE % (self.context[0], self.signature)

    def __str__(self):
        return self.__repr__()


class SignedObject(object):
    """
    Basic object that supports an attributes signature.
    """

    def __init__(self, _force=False, **kwargs):
        self._signature = self.attributes

        for k, v in kwargs.iteritems():
            if _force:
                self._signature.add(k)

            if k in self._signature or _force:
                self.__setattr__(k, v, _force=True)

        # Init missing properties
        for k in self.attributes:
            if not hasattr(self, k):
                self.__setattr__(k, None)

        # If for some reason '_signature' was passed as __init__ **kwargs, remove it.
        if '_signature' in self.attributes:
            self.attributes.remove('_signature')

    @property
    def attributes(self):
        """
        During the __init__ process, self._signature doesn't yet exist, so to avoid errors we pass and empty set if
        self._signature hasn't been defined yet.
        """
        return getattr(self, '_signature', set())

    def to_dict(self):
        return {k: v for k, v in zip(self.attributes, [getattr(self, k) for k in self.attributes])}

    def __repr__(self):
        return self.to_dict().__repr__()

    def __setattr__(self, key, value, _force=False):
        """
        Wrap the default __setattr__ functionality to obey signature.  _force is used during __init__() to init
        object attributes before _signature has been assigned.
        """
        if key in self.attributes or _force or key == '_signature':
            super(SignedObject, self).__setattr__(key, value)
        else:
            raise SignatureException(context=(key, value, _force), signature=list(self.attributes))
