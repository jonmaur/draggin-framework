from rect import Rect
from math import floor

class HashMap(object):
    """
    Hashmap is a broad-phase collision detection strategy, which is quick
    enough to build each frame.
    """
    def __init__(self, cell_size):
        self.cell_size = cell_size
        self.grid = {}

    @classmethod
    def from_objects(cls, cell_size, objects):
        """
        Build a HashMap from a list of objects which have a .rect attribute.
        """
        h = cls(cell_size)
        g = h.grid
        for o in objects:
            point = o.rect.left, o.rect.bottom
            k = "%s%s" % (int((floor(point[0]/cell_size))*cell_size), int((floor(point[1]/cell_size))*cell_size))
            g.setdefault(k,[]).append(o)
        return h

    def key(self, point):
        cell_size = self.cell_size
        return "%s%s" % (int((floor(point[0]/cell_size))*cell_size), int((floor(point[1]/cell_size))*cell_size))

    def insert(self, obj, rect):
        """
        Insert obj into the hashmap, based on rect.
        """
        self.grid.setdefault(self.key((rect.left, rect.bottom)), []).append(obj)

    def query(self, point):
        """
        Return all objects in and around the cell specified by point.
        """
        objects = []
        x,y = point
        s = self.cell_size
        for p in (x-s,y-s),(x-s,y),(x-s,y+s),(x,y-s),(x,y),(x,y+s),(x+s,y-s),(x+s,y),(x+s,y+s):
            objects.extend(self.grid.setdefault(self.key(p), []))
        return objects 

