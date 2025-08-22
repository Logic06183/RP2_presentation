const { chromium } = require('playwright');

async function testPresentation() {
    const browser = await chromium.launch({ headless: false });
    const page = await browser.newPage();
    
    try {
        // Navigate to the presentation
        await page.goto(`file://${process.cwd()}/interactive_presentation.html`);
        
        // Wait for page to load
        await page.waitForTimeout(2000);
        
        console.log('✅ Presentation loaded successfully');
        
        // Test navigation
        console.log('Testing slide navigation...');
        
        // Check initial slide
        const currentSlide = await page.textContent('#currentSlide');
        console.log(`Current slide: ${currentSlide}`);
        
        // Navigate to next slide
        await page.click('#nextBtn');
        await page.waitForTimeout(1000);
        
        const newSlide = await page.textContent('#currentSlide');
        console.log(`After clicking next: ${newSlide}`);
        
        // Test keyboard navigation
        await page.keyboard.press('ArrowRight');
        await page.waitForTimeout(1000);
        
        const keyboardSlide = await page.textContent('#currentSlide');
        console.log(`After keyboard navigation: ${keyboardSlide}`);
        
        // Test SVG containers
        console.log('Checking SVG containers...');
        
        // Navigate to slide with study distribution chart (slide 3)
        await page.keyboard.press('ArrowRight');
        await page.waitForTimeout(1000);
        
        const studyChartExists = await page.isVisible('#studyDistributionChart svg');
        console.log(`Study distribution chart visible: ${studyChartExists}`);
        
        // Navigate to slide with climate comparison (slide 4)
        await page.keyboard.press('ArrowRight');
        await page.waitForTimeout(1000);
        
        const climateChartExists = await page.isVisible('#climateComparisonChart svg');
        console.log(`Climate comparison chart visible: ${climateChartExists}`);
        
        // Check for SVG formatting issues
        console.log('Analyzing SVG formatting...');
        
        // Take screenshots of each slide with visualizations
        for (let i = 2; i < 8; i++) {
            // Navigate to specific slide
            for (let j = 0; j < i; j++) {
                await page.keyboard.press('ArrowRight');
                await page.waitForTimeout(500);
            }
            
            // Take screenshot
            await page.screenshot({ 
                path: `slide_${i + 1}_screenshot.png`, 
                fullPage: true 
            });
            console.log(`📸 Screenshot taken for slide ${i + 1}`);
            
            // Reset to first slide
            await page.keyboard.press('Home');
            await page.waitForTimeout(500);
        }
        
        // Check for common SVG issues
        const svgElements = await page.$$('svg');
        for (let i = 0; i < svgElements.length; i++) {
            const svg = svgElements[i];
            const viewBox = await svg.getAttribute('viewBox');
            const width = await svg.getAttribute('width');
            const height = await svg.getAttribute('height');
            
            console.log(`SVG ${i + 1}:`);
            console.log(`  ViewBox: ${viewBox}`);
            console.log(`  Width: ${width}`);
            console.log(`  Height: ${height}`);
            
            // Check if text elements are positioned correctly
            const textElements = await svg.$$('text');
            let textIssues = 0;
            
            for (const text of textElements) {
                const x = await text.getAttribute('x');
                const y = await text.getAttribute('y');
                if (!x || !y || x === '0' || y === '0') {
                    textIssues++;
                }
            }
            
            if (textIssues > 0) {
                console.log(`  ⚠️ Found ${textIssues} potential text positioning issues`);
            } else {
                console.log(`  ✅ Text positioning looks good`);
            }
        }
        
        console.log('✅ Testing completed successfully');
        
    } catch (error) {
        console.error('❌ Error during testing:', error);
    } finally {
        await browser.close();
    }
}

testPresentation();