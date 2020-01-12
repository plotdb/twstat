(->
  patch = -> it.replace /臺/g, '台'
  inst = (opt = {}) ->
    @root = if typeof(opt.root) == typeof('') => document.querySelector(opt.root) else opt.root
    @ <<< {lc: {}, type: opt.type}
    @

  inst.prototype = Object.create(Object.prototype) <<< do
    init: ->
      {root, type} = @{root, type}
      ld$.fetch "assets/lib/pdmap.tw/#type.topo.json", {method: \GET}, {type: \json}
        .then (topo) ~>
          @lc.topo = topo
          ld$.fetch "assets/lib/pdmap.tw/#type.meta.json", {method: \GET}, {type: \json}
        .then (meta) ~>
          @lc.meta = meta
          @lc.features = features = topojson.feature(@lc.topo, @lc.topo.objects["pdmaptw"]).features
          @lc.path = path = d3.geoPath().projection(pdmaptw.projection)
          d3.select(root).append(\svg).append(\g)
            .selectAll \path
            .data features
            .enter!
              .append \path
              .attr \d, path

    fit: ->
      root = @root
      g = ld$.find root, \g, 0
      svg = d3.select(root).select(\svg)
      svg.attr \width, \100%
      svg.attr \height, \100%
      bcr = root.getBoundingClientRect!
      bbox = g.getBBox!
      [width,height] = [bcr.width,bcr.height]
      padding = 20
      scale = Math.min((width - 2 * padding) / bbox.width, (height - 2 * padding) / bbox.height)
      [w,h] = [width / 2, height / 2]
      g.setAttribute(
        \transform
        "translate(#w,#h) scale(#scale) translate(#{-bbox.x - bbox.width/2},#{-bbox.y - bbox.height/2})"
      )

  pdmaptw.create = (opt = {}) -> new inst opt

  lc = {}
  lc.obj = pdmaptw.create {root: (ld$.find(document, \#map, 0)), type: \county}
  lc.obj.init!
    .then ->
      ld$.fetch "assets/lib/twstat/county/index/index.json", {method: \GET}, {type: \json}
    .then (list) ->
      view = new ldView do
        root: document.body
        action: input: do
          select: -> retrieve view.get(\select).value
        handler:
          option: do
            list: -> list
            handle: ({node, data}) -> node.innerText = data
  retrieve = (name="道路里程長度") -> 
    ld$.fetch "assets/lib/twstat/county/index/#name.json", {method: \GET}, {type: \json}
      .then (data) ->
        lc.data = data
      .then -> 
        obj = lc.obj
        obj.fit!
        data = lc.data[* - 1]
        max = Math.max.apply null, obj.lc.meta.name.map(-> data[it] or 0)
        d3.select obj.root .selectAll \path
          .attr \fill, ->
            name = patch(obj.lc.meta.name[it.properties.c])
            v = (data[name] or 0)/max
            #v = if it.properties.tid == \T => 0.2 + Math.random! * 0.2 else Math.random! * 0.2
            #if it.properties.value => v = 1 else v = Math.random!
            d3.interpolateMagma v
          .attr \stroke, -> \#000
          .attr \stroke-width, -> 0.00

)!
