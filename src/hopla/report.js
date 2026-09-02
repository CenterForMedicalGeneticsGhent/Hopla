(function(){
  var node = document.getElementById('hopla-data');
  var binary = atob(node.textContent.trim());
  var bytes = new Uint8Array(binary.length);
  for (var i = 0; i < binary.length; i++) bytes[i] = binary.charCodeAt(i);
  var stream = new Blob([bytes]).stream().pipeThrough(new DecompressionStream('gzip'));
  new Response(stream).text().then(function(text){ start(JSON.parse(text)); });

  function start(D){
    var M = D.meta, P = M.palette, LC = M.letterColors, MARK = M.markColor;
    var CHRS = M.chromosomes, SIZES = M.sizes;
    var OFF = {}, GENOME = 0;
    CHRS.forEach(function(c){ OFF[c] = GENOME; GENOME += SIZES[c]; });
    var CONFIG = {responsive:true, displaylogo:false, displayModeBar:'hover'};

    function fmt(v){ return Math.round(v).toLocaleString('en-US'); }
    function has(name){ return D[name] && D[name].rows; }
    function where(name, keep){
      var t = D[name], out = [];
      if (!t) return out;
      for (var i = 0; i < t.rows; i++) if (keep(t.data, i)) out.push(i);
      return out;
    }
    function pick(values, index){
      var out = new Array(index.length);
      for (var i = 0; i < index.length; i++) out[i] = values[index[i]];
      return out;
    }
    function extent(values){
      var lo = Infinity, hi = -Infinity;
      for (var i = 0; i < values.length; i++){
        var v = values[i];
        if (v === null || !isFinite(v)) continue;
        if (v < lo) lo = v;
        if (v > hi) hi = v;
      }
      return [lo, hi];
    }
    function translucent(hex){
      var value = parseInt(hex.slice(1), 16);
      return 'rgba(' + [(value >> 16) & 255, (value >> 8) & 255, value & 255].join(',') + ',0.2)';
    }
    function thin(index, fraction){
      if (!fraction || fraction >= 1 || index.length < 20) return index;
      var step = Math.max(1, Math.round(1 / fraction)), out = [];
      for (var i = 0; i < index.length; i += step) out.push(index[i]);
      return out;
    }

    function layout(options){
      return {
        height: options.height,
        margin: options.margin || {l:58, r:14, t:14, b:30},
        showlegend: false,
        hovermode: options.hovermode || 'closest',
        font: {family: M.font, size: 11},
        paper_bgcolor: '#fff',
        plot_bgcolor: '#fff',
        xaxis: Object.assign({title:{text: options.xtitle || '', standoff: 2}, zeroline:false, showgrid:false, showticklabels:false}, options.xaxis || {}),
        yaxis: Object.assign({title:{text: options.ytitle || '', standoff: 2}, zeroline:false, showgrid:false}, options.yaxis || {}),
        shapes: options.shapes || [],
        annotations: options.annotations || []
      };
    }

    function chromosomeAxis(){
      return {
        showticklabels: true,
        tickmode: 'array',
        tickvals: CHRS.map(function(c){ return OFF[c] + SIZES[c] / 2; }),
        ticktext: CHRS.map(function(c){ return c.replace('chr',''); }),
        tickfont: {size: 9},
        range: [0, GENOME]
      };
    }

    function chromosomeShapes(lo, hi){
      var shapes = CHRS.map(function(c){
        return {type:'line', x0:OFF[c], x1:OFF[c], y0:lo, y1:hi, line:{color:'#0f172a', width:0.5}};
      });
      shapes.push({type:'line', x0:GENOME, x1:GENOME, y0:lo, y1:hi, line:{color:'#0f172a', width:0.5}});
      return shapes;
    }

    function regionShapes(lo, hi, chrom, flanks){
      var shapes = [];
      M.regions.forEach(function(region){
        if (chrom && region.chrom !== chrom) return;
        var base = chrom ? 0 : OFF[region.chrom];
        if (base === undefined) return;
        [region.start, region.end].forEach(function(position){
          shapes.push({type:'line', x0:base+position, x1:base+position, y0:lo, y1:hi, line:{color:MARK, width:1.2}});
        });
        if (flanks === false) return;
        [region.start - M.flank, region.end + M.flank].forEach(function(position){
          shapes.push({type:'line', x0:base+position, x1:base+position, y0:lo, y1:hi, line:{color:MARK, width:0.8, dash:'dot'}});
        });
      });
      return shapes;
    }

    function cytobandShapes(chrom, y, thickness){
      var bands = M.cytobands[chrom], shapes = [];
      if (!bands) return shapes;
      for (var i = 0; i < bands.start.length; i++){
        var stain = bands.stain[i] || '';
        var special = stain.indexOf('acen') >= 0 || stain.indexOf('gvar') >= 0 || stain.indexOf('stalk') >= 0;
        shapes.push({
          type:'rect', x0:bands.start[i], x1:bands.end[i],
          y0:y - thickness/2, y1:y + thickness/2,
          fillcolor: special ? '#111827' : (i % 2 ? '#a9a9a9' : '#d3d3d3'),
          line:{width:0}
        });
      }
      return shapes;
    }

    function runs(letters, positions){
      var blocks = [], start = 0, i;
      for (i = 1; i <= letters.length; i++){
        if (i === letters.length || letters[i] !== letters[start]){
          blocks.push({letter: letters[start], last: i - 1});
          start = i;
        }
      }
      var edges = [positions[0]];
      for (i = 0; i < blocks.length - 1; i++){
        var last = blocks[i].last;
        edges.push(positions[last] + (positions[last + 1] - positions[last]) / 2);
      }
      edges.push(positions[positions.length - 1]);
      return blocks.map(function(block, index){
        return {letter: block.letter, start: edges[index], end: edges[index + 1]};
      });
    }

    var BUILD = {};

    BUILD.depth = function(spec){
      var d = D.variant_depth.data;
      var mine = where('variant_depth', function(d, i){ return d.filter_level[i] === spec.level && d.sample[i] === spec.sample; });
      var level = where('variant_depth', function(d, i){ return d.filter_level[i] === spec.level; });
      var counts = extent(pick(d.count, level));
      return {
        traces: [{type:'bar', x: pick(d.depth, mine), y: pick(d.count, mine), hoverinfo:'x+y', marker:{color:P[0]}}],
        layout: layout({
          height: spec.height, xtitle: M.labels[spec.sample], ytitle: 'density',
          xaxis: {showticklabels:true, range:[extent(pick(d.bin_start, level))[0], extent(pick(d.bin_end, level))[1]]},
          yaxis: {range:[0, Math.max(1, counts[1])]}
        })
      };
    };

    BUILD.density = function(spec){
      var d = D.variant_density.data, sample = M.samples[0];
      var mine = where('variant_density', function(d, i){ return d.filter_level[i] === spec.level && d.sample[i] === sample; });
      var x = [], y = [], text = [];
      mine.forEach(function(i){
        var chrom = d.chrom[i];
        if (OFF[chrom] === undefined) return;
        x.push(OFF[chrom] + d.start[i]);
        y.push(d.count[i]);
        text.push(chrom + ':' + fmt(d.start[i]) + '-' + fmt(d.end[i]));
      });
      var top = extent(y)[1] || 1, range = [-top * 0.1, top * 1.1];
      return {
        traces: [{type:'scatter', mode:'markers', x:x, y:y, text:text, hoverinfo:'y+text',
                  marker:{color:P[0], size:M.dot * 2, opacity:0.6}}],
        layout: layout({
          height: spec.height, ytitle: 'variant count', hovermode: 'x unified',
          xaxis: chromosomeAxis(), yaxis: {range: range},
          shapes: chromosomeShapes(range[0], range[1]).concat(regionShapes(range[0], range[1], null, true))
        })
      };
    };

    BUILD.cn = function(spec){
      var d = D.copy_number.data;
      var mine = where('copy_number', function(d, i){ return d.sample[i] === spec.sample; });
      var x = [], y = [], text = [], original = [], color = [], symbol = [], opacity = [];
      mine.forEach(function(i){
        var chrom = d.chrom[i], value = d.log2_ratio[i];
        if (OFF[chrom] === undefined || value === null || !isFinite(value)) return;
        var high = value > 5, low = value < -5;
        x.push(OFF[chrom] + d.start[i]);
        y.push(high ? 5 : (low ? -5 : value));
        text.push(chrom + ':' + fmt(d.start[i]) + '-' + fmt(d.end[i]));
        original.push(value);
        color.push(high || low ? P[5] : P[0]);
        symbol.push(high ? 'triangle-up' : (low ? 'triangle-down' : 'circle'));
        opacity.push(high || low ? 1 : 0.6);
      });
      var range = [-5, 5];
      var traces = [{
        type:'scatter', mode:'markers', x:x, y:y, text:text, customdata:original,
        hovertemplate:'%{customdata}<br>%{text}<extra></extra>',
        marker:{color:color, size:M.dot * 2, opacity:opacity, symbol:symbol}
      }];
      if (has('cn_segments')){
        var s = D.cn_segments.data;
        where('cn_segments', function(s, i){ return s.sample[i] === spec.sample; }).forEach(function(i){
          var chrom = s.chrom[i];
          if (OFF[chrom] === undefined) return;
          traces.push({
            type:'scatter', mode:'lines',
            x:[OFF[chrom] + s.start[i], OFF[chrom] + s.end[i]],
            y:[s.seg_mean[i], s.seg_mean[i]],
            hoverinfo:'text',
            text:'segment: ' + chrom + ':' + fmt(s.start[i]) + '-' + fmt(s.end[i]),
            line:{color:P[1], width:M.dot}
          });
        });
      }
      return {
        traces: traces,
        layout: layout({
          height: spec.height, xtitle: M.labels[spec.sample], ytitle: 'log2(ratio)',
          xaxis: chromosomeAxis(), yaxis: {range: range, fixedrange:true},
          shapes: chromosomeShapes(range[0], range[1]).concat(regionShapes(range[0], range[1], null, true))
        })
      };
    };

    function bafTrace(index, d){
      return {
        type:'scatter', mode:'markers',
        x: pick(d.pos, index),
        y: index.map(function(i){ return d.af[i] * 100; }),
        text: index.map(function(i){ return d.chrom[i] + ':' + fmt(d.pos[i]); }),
        hoverinfo:'y+text',
        marker:{color:P[0], size:M.dot * 2, opacity:0.6}
      };
    }

    BUILD.rbaf = function(spec){
      var d = D.baf.data;
      var region = M.regions.filter(function(r){ return r.label === spec.region; })[0];
      var from = Math.max(1, region.start - M.flank);
      var to = Math.min(SIZES[region.chrom], region.end + M.flank);
      var mine = where('baf', function(d, i){
        return d.sample[i] === spec.sample && d.chrom[i] === region.chrom && d.pos[i] > from && d.pos[i] < to;
      });
      return {
        traces: [bafTrace(mine, d)],
        layout: layout({
          height: spec.height, ytitle: 'BAF (%)',
          xaxis: {range:[from, to]}, yaxis: {range:[-15, 115], fixedrange:true},
          shapes: regionShapes(-5, 105, region.chrom, false),
          annotations: [{x:(from + to) / 2, y:-10, text:M.labels[spec.sample], showarrow:false, font:{size:11}}]
        })
      };
    };

    BUILD.gbaf = function(spec){
      var d = D.baf.data;
      var mine = thin(where('baf', function(d, i){
        return d.sample[i] === spec.sample && d.chrom[i] === spec.chrom;
      }), M.limitBaf);
      return {
        traces: [bafTrace(mine, d)],
        layout: layout({
          height: spec.height, ytitle: 'BAF (%)',
          xaxis: {range:[0, SIZES[spec.chrom]]}, yaxis: {range:[-15, 132], fixedrange:true},
          shapes: cytobandShapes(spec.chrom, 124, 8).concat(regionShapes(-5, 118, spec.chrom, true)),
          annotations: [{x:SIZES[spec.chrom] / 2, y:-10, text:spec.chrom, showarrow:false, font:{size:11}}]
        })
      };
    };

    BUILD.men = function(spec){
      var d = D.mendelian.data;
      var mine = where('mendelian', function(d, i){ return d.sample[i] === spec.sample; });
      // Window rows arrive grouped, so order them before drawing connected lines.
      var at = function(i){ return OFF[d.chrom[i]] === undefined ? null : OFF[d.chrom[i]] + d.start[i]; };
      mine = mine.filter(function(i){ return at(i) !== null; }).sort(function(a, b){ return at(a) - at(b); });
      var x = [], text = [];
      mine.forEach(function(i){
        x.push(at(i));
        text.push(d.chrom[i] + ':' + fmt(d.start[i]) + '-' + fmt(d.end[i]));
      });
      var traces = [], top = 50;
      [['trio', P[0], 'solid', 'trio errors'],
       ['father', P[1], 'dot', 'father errors'],
       ['mother', P[2], 'dot', 'mother errors']].forEach(function(entry){
        if (!d[entry[0]]) return;
        var y = pick(d[entry[0]], mine);
        var span = extent(y);
        if (span[1] > top) top = span[1];
        traces.push({type:'scatter', mode:'lines', x:x, y:y, text:text, name:entry[3], hoverinfo:'name+y+text',
                     line:{color:entry[1], width:M.dot, dash:entry[2]}, fill:'tozeroy',
                     fillcolor:translucent(entry[1])});
      });
      var range = [0, top];
      return {
        traces: traces,
        layout: layout({
          height: spec.height, xtitle: M.labels[spec.sample], ytitle: 'mendelian error count',
          xaxis: chromosomeAxis(), yaxis: {range: range},
          shapes: chromosomeShapes(range[0], range[1]).concat(regionShapes(range[0], range[1], null, true))
        })
      };
    };

    BUILD.pm = function(spec){
      var d = D.parent_mapping.data;
      var mine = thin(where('parent_mapping', function(d, i){
        return d.child[i] === spec.sample && d.chrom[i] === spec.chrom;
      }), M.limitPm);
      var x = [], y = [], color = [], text = [];
      mine.forEach(function(i){
        var father = d.origin[i] === 'father';
        var het = d.zygosity[i] === 'heterozygous';
        x.push(d.pos[i]);
        y.push(father ? (het ? 5 : 4) : (het ? 2 : 1));
        color.push(father ? P[0] : P[1]);
        text.push(d.chrom[i] + ':' + fmt(d.pos[i]));
      });
      return {
        traces: [{type:'scatter', mode:'markers', x:x, y:y, text:text, hoverinfo:'text',
                  marker:{color:color, size:M.dot * 3, symbol:'cross-thin-open', line:{color:color, width:1}}}],
        layout: layout({
          height: spec.height, xtitle: spec.chrom,
          xaxis: {range:[0, SIZES[spec.chrom]]},
          yaxis: {range:[0.5, 6], fixedrange:true, showticklabels:false},
          shapes: cytobandShapes(spec.chrom, 3, 0.25).concat(regionShapes(0.5, 5.5, spec.chrom, true))
        })
      };
    };

    BUILD.pmlegend = function(spec){
      var father = M.parents && M.parents[spec.sample] ? M.parents[spec.sample].father : null;
      var mother = M.parents && M.parents[spec.sample] ? M.parents[spec.sample].mother : null;
      var labels;
      if (father && mother){
        labels = ['father 0/1 --- mother 0/0|1/1 --- child 0/1',
                  'father 0/1 --- mother 0/0|1/1 --- child 0/0|1/1',
                  'father 0/0|1/1 --- mother 0/1 --- child 0/1',
                  'father 0/0|1/1 --- mother 0/1 --- child 0/0|1/1'];
      } else if (father){
        labels = ['father 0/1 --- child 0/1', 'father 0/1 --- child 0/0|1/1',
                  'father 0/0|1/1 --- child 0/1', 'father 0/0|1/1 --- child 0/0|1/1'];
      } else {
        labels = ['mother 0/0|1/1 --- child 0/1', 'mother 0/0|1/1 --- child 0/0|1/1',
                  'mother 0/1 --- child 0/1', 'mother 0/1 --- child 0/0|1/1'];
      }
      var rows = [[5, labels[0], P[0]], [4, labels[1], P[0]], [2, labels[2], P[1]], [1, labels[3], P[1]]];
      return {
        traces: [{type:'scatter', mode:'markers', x:[0], y:[0], hoverinfo:'none', marker:{color:'#fff', size:0.1}}],
        layout: layout({
          height: spec.height,
          xaxis: {range:[0, 1]}, yaxis: {range:[0.5, 6], fixedrange:true, showticklabels:false},
          annotations: rows.map(function(row){
            return {x:0.5, y:row[0], text:row[1], showarrow:false, font:{size:10, color:row[2]}};
          })
        })
      };
    };

    BUILD.hap = function(spec){
      var d = D.haplotypes.data;
      var count = M.samples.length;
      var inChromosome = where('haplotypes', function(d, i){ return d.chrom[i] === spec.chrom; });
      var traces = [], annotations = [];
      var regionChromosome = M.regions.some(function(region){ return region.chrom === spec.chrom; });
      var showPoints = M.keepChromosomesOnly || M.keepRegionsOnly ? regionChromosome : true;
      M.samples.forEach(function(sample, order){
        var base = count * 3 - (order + 1) * 3;
        annotations.push({x:0, y:base + 2, text:M.labels[sample], showarrow:false, xanchor:'left', font:{size:10}});
        [1, 2].forEach(function(strand){
          var mine = inChromosome.filter(function(i){ return d.sample[i] === sample && d.strand[i] === strand; });
          if (!mine.length) return;
          mine.sort(function(a, b){ return d.pos[a] - d.pos[b]; });
          var y = strand === 1 ? base + 1 : base;
          var positions = pick(d.pos, mine), letters = pick(d.letter, mine);
          var genotypes = pick(d.genotype, mine);
          if (letters.every(function(letter){ return letter === 'X'; }) ||
              genotypes.every(function(genotype){ return genotype === 'NA'; })) return;
          var px = [], py = [], pc = [], pt = [], ps = [];
          mine.forEach(function(i){
            if (d.genotype[i] === 'NA') return;
            if (!showPoints) return;
            if (M.keepRegionsOnly && !M.regions.some(function(region){
              return region.chrom === spec.chrom && d.pos[i] >= region.start - M.flank && d.pos[i] <= region.end + M.flank;
            })) return;
            px.push(d.pos[i]);
            py.push(y);
            pc.push(LC[d.letter[i]] || '#ffffff');
            pt.push(spec.chrom + ':' + fmt(d.pos[i]) + ' (' + d.genotype[i] + ')');
            ps.push(d.is_corrected[i] ? 'circle' : 'square');
          });
          if (px.length){
            traces.push({type:'scatter', mode:'markers', x:px, y:py, text:pt, hoverinfo:'text',
                         marker:{color:pc, symbol:ps, size:M.dot * 4, line:{color:pc, width:1}}});
          }
          var blocks = runs(letters, positions);
          blocks.forEach(function(block){
            traces.push({type:'scatter', mode:'lines', x:[block.start, block.end], y:[y, y], hoverinfo:'none',
                         line:{color:LC[block.letter] || '#ffffff', width:M.dot * 2}});
          });
          var breaks = blocks.slice(1).map(function(block){ return block.start; });
          if (breaks.length){
            traces.push({type:'scatter', mode:'markers', x:breaks,
                         y:breaks.map(function(){ return y + (strand === 1 ? 0.3 : -0.3); }),
                         hoverinfo:'none',
                         marker:{symbol: strand === 1 ? 'y-down-open' : 'y-up-open', color:MARK, size:M.dot * 6}});
          }
        });
      });
      var ceiling = count * 3 + 1;
      return {
        traces: traces,
        layout: layout({
          height: spec.height, xtitle: spec.chrom,
          xaxis: {range:[0, SIZES[spec.chrom]]},
          yaxis: {range:[-1, ceiling + 1], fixedrange:true, showticklabels:false},
          annotations: annotations,
          shapes: cytobandShapes(spec.chrom, ceiling, 0.35).concat(regionShapes(-0.5, ceiling - 0.5, spec.chrom, true))
        })
      };
    };

    function draw(element){
      var spec = JSON.parse(element.getAttribute('data-spec'));
      spec.height = element.clientHeight || 240;
      var builder = BUILD[spec.kind];
      if (!builder) return;
      try {
        var figure = builder(spec);
        Plotly.newPlot(element, figure.traces, figure.layout, CONFIG);
      } catch (error){
        element.textContent = 'Could not render this figure.';
        console.error(spec, error);
      }
    }

    var observer = new IntersectionObserver(function(entries){
      entries.forEach(function(entry){
        if (!entry.isIntersecting) return;
        observer.unobserve(entry.target);
        draw(entry.target);
      });
    }, {rootMargin: '400px'});
    document.querySelectorAll('.fig').forEach(function(element){ observer.observe(element); });
  }
})();
