# blog-updater

### Example

```js
var blogUpdater = require("blog-updater");

blogUpdater.update({
  repoUrl: "https://github.com/DAB0mB/blog-updater",
  srcPath: __dirname + "/blog.html",
  dstPath: __dirname + "/updatedBlog.html"
}, function(err) {
  console.log(err);
})
```