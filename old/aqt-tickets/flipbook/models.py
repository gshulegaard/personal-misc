from django.db import models

# Create your models here.

# Flipbook base class
class Base(models.Model):
    url = models.URLField() # Default length is 200.
    header = models.TextField()
    intro = models.TextField(default="") # Intro paragraph before bullets.
    form_header = models.TextField() # Default value: 'Discorver ATMS Today'
    form_button = models.TextField() # Default value: 'Discover More'
    slug = models.SlugField(unique=True)
    # Start page META data for marketing...
    title = models.TextField(default="")
    meta_description = models.CharField(default="", max_length=150)
    og_article_tag = models.TextField(default="")
    def __str__(self):
        return self.header

# Flipbook image class
class Image(models.Model):
    base = models.ForeignKey(Base)
    name = models.TextField()
    def __str__(self):
        return self.name

# Flipbook bullet class
class Bullet(models.Model):
    base = models.ForeignKey(Base)
    text = models.TextField()
    def __str__(self):
        return self.text
