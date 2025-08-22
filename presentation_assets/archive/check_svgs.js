const fs = require('fs');

function analyzeSVG(filename) {
    try {
        const svgContent = fs.readFileSync(filename, 'utf8');
        console.log(`\n📊 Analyzing ${filename}:`);
        
        // Check for basic SVG structure
        if (!svgContent.includes('<svg')) {
            console.log('❌ No SVG element found');
            return;
        }
        
        // Extract viewBox
        const viewBoxMatch = svgContent.match(/viewBox="([^"]+)"/);
        if (viewBoxMatch) {
            console.log(`✅ ViewBox: ${viewBoxMatch[1]}`);
        } else {
            console.log('⚠️ No viewBox found');
        }
        
        // Check for text elements and their positioning
        const textElements = svgContent.match(/<text[^>]*>/g) || [];
        console.log(`📝 Found ${textElements.length} text elements`);
        
        let positionIssues = 0;
        textElements.forEach((text, index) => {
            const xMatch = text.match(/x="([^"]+)"/);
            const yMatch = text.match(/y="([^"]+)"/);
            
            if (!xMatch || !yMatch) {
                positionIssues++;
                console.log(`⚠️ Text element ${index + 1} missing x or y coordinates`);
            } else {
                const x = parseFloat(xMatch[1]);
                const y = parseFloat(yMatch[1]);
                if (isNaN(x) || isNaN(y)) {
                    positionIssues++;
                    console.log(`⚠️ Text element ${index + 1} has invalid coordinates: x="${xMatch[1]}", y="${yMatch[1]}"`);
                }
            }
        });
        
        if (positionIssues === 0) {
            console.log('✅ All text elements have valid positioning');
        }
        
        // Check for font-family issues
        const fontFamilies = svgContent.match(/font-family="([^"]+)"/g) || [];
        const uniqueFonts = [...new Set(fontFamilies)];
        console.log(`🔤 Fonts used: ${uniqueFonts.join(', ')}`);
        
        // Check for overlapping elements (basic check)
        const rectElements = svgContent.match(/<rect[^>]*>/g) || [];
        console.log(`📐 Found ${rectElements.length} rectangle elements`);
        
        // Look for potential text overflow issues
        const longTexts = svgContent.match(/<text[^>]*>[^<]{50,}<\/text>/g) || [];
        if (longTexts.length > 0) {
            console.log(`⚠️ Found ${longTexts.length} potentially long text elements that might overflow`);
        }
        
        // Check for missing or empty text content
        const emptyTexts = svgContent.match(/<text[^>]*><\/text>/g) || [];
        if (emptyTexts.length > 0) {
            console.log(`⚠️ Found ${emptyTexts.length} empty text elements`);
        }
        
        console.log(`📏 File size: ${(svgContent.length / 1024).toFixed(1)} KB`);
        
    } catch (error) {
        console.log(`❌ Error reading ${filename}:`, error.message);
    }
}

// List of SVG files to check
const svgFiles = [
    'study_distribution_chart.svg',
    'research_methodology_flow.svg',
    'climate_comparison_infographic.svg',
    'research_portfolio_breakdown.svg'
];

console.log('🔍 SVG Analysis Report\n' + '='.repeat(50));

svgFiles.forEach(analyzeSVG);

console.log('\n✅ Analysis complete!');