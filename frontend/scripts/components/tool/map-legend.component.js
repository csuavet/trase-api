import LegendChoroTemplate from 'ejs!templates/tool/map/legend-choro.ejs';
import LegendContextTemplate from 'ejs!templates/tool/map/legend-context.ejs';
import 'style/components/tool/map/map-legend.scss';
import abbreviateNumber from 'utils/abbreviateNumber';

export default class {

  onCreated() {
    this.el = document.querySelector('.js-map-legend');
    this.el.addEventListener('click', () => { this.callbacks.onToggleMapLayerMenu(); });
    this.choro = document.querySelector('.js-map-legend-choro');
    this.context = document.querySelector('.js-map-legend-context');
    this.map = document.querySelector('.c-map');
    this.attribution = document.querySelector('.js-map-attribution');
    this.mapControlScale = document.querySelector('.leaflet-control-scale');
    this.mapControlZoom = document.querySelector('.leaflet-control-zoom');
    this.mapControlSwitcher = document.querySelector('.js-basemap-switcher');
    this.warningsContainer = document.querySelector('.js-map-warnings-container');
    this.warnings = document.querySelector('.js-map-warnings');

    const zoom = document.querySelector('.leaflet-control-zoom');
    const scale = document.querySelector('.leaflet-control-scale');
    zoom.addEventListener('mouseenter', () => { scale.classList.toggle('-visible', true); });
    zoom.addEventListener('mouseleave', () => { scale.classList.toggle('-visible', false); });
  }

  updateChoroplethLegend({ choroplethLegend, selectedMapContextualLayersData }) {
    this._toggleLegend(choroplethLegend, selectedMapContextualLayersData);
    this._setupChoro(choroplethLegend);
    this._updateMapControlsPosition();
  }

  updateContextLegend({ choroplethLegend, selectedMapContextualLayersData }) {
    this._toggleLegend(choroplethLegend, selectedMapContextualLayersData);
    this._renderContext(selectedMapContextualLayersData);
    this._updateMapControlsPosition();
  }

  highlightChoroplethBucket(bucketClass) {
    if (this.currentBuckets === undefined) {
      return;
    }
    for (var i = 0; i < this.currentBuckets.length; i++) {
      this.currentBuckets[i].classList.toggle('-highlighted', false);
    }
    if (bucketClass === undefined || bucketClass === null) {
      return;
    }
    const bucket = this.choro.getElementsByClassName(bucketClass)[0];
    if (bucket === undefined) {
      return;
    }
    bucket.classList.toggle('-highlighted', true);
  }

  selectMapDimensions(selectedMapDimensionsWarnings) {
    this.warningsContainer.classList.toggle('-visible', selectedMapDimensionsWarnings !== null);
    if (selectedMapDimensionsWarnings !== null) {
      this.warnings.innerHTML = selectedMapDimensionsWarnings;
    }
  }

  _setupChoro(choroplethLegend) {
    if (this.el.hasChildNodes()) {
      this._cleanChoro();
    }

    if (choroplethLegend !== null) {
      this._renderChoro(choroplethLegend);
    }
  }

  _toggleLegend(choroplethLegend, selectedMapContextualLayersData) {
    if (choroplethLegend === null && (selectedMapContextualLayersData === undefined || !selectedMapContextualLayersData.length)) {
      this._hideLegend();
    } else {
      this._showLegend();
    }
  }

  _showLegend() {
    this.el.classList.remove('-hidden');
    this.map.classList.add('-have-legend');
  }

  _hideLegend() {
    this.el.classList.add('-hidden');
    this.map.classList.remove('-have-legend');
  }

  _cleanChoro() {
    this.choro.innerHTML = '';
  }

  _renderChoro(choroplethLegend) {
    const cssClass = (choroplethLegend.isBivariate) ? '-bidimensional' : '-horizontal';

    const html = LegendChoroTemplate({
      title: choroplethLegend.titles,
      colors: choroplethLegend.colors,
      cssClass,
      bucket: choroplethLegend.bucket,
      isBivariate: choroplethLegend.isBivariate,
      abbreviateNumber
    });

    this.choro.innerHTML = html;
    this.currentBuckets = Array.prototype.slice.call(this.choro.getElementsByClassName('bucket'))
                  .concat(Array.prototype.slice.call(this.choro.getElementsByClassName('bullet')));
  }

  _renderContext(layers) {
    const html = LegendContextTemplate({
      layers
    });
    this.context.innerHTML = html;
  }

  _updateMapControlsPosition() {
    const mapFooterHeight = this.el.offsetHeight + this.attribution.offsetHeight;
    this.mapControlSwitcher.style.bottom = `${mapFooterHeight + 8}px`;
    this.mapControlZoom.style.bottom = `${mapFooterHeight + 48}px`;
    this.mapControlScale.style.bottom = `${mapFooterHeight + this.mapControlScale.offsetHeight - 88}px`;
  }
}
