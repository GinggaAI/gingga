# Manual Testing Documentation

This directory contains all manual testing guides and quality assurance procedures for the Gingga Rails application.

---

## 📋 Testing Guides

### Primary Testing Documentation

1. **[Comprehensive Testing Guide](./comprehensive_testing_guide.md)** ⭐️ **START HERE**
   - Complete manual testing procedures for all features
   - Suitable for any user (technical or non-technical)
   - Step-by-step instructions with expected results
   - Browser testing and mobile verification
   - Issue reporting templates

2. **[Testing New Screens](./testing_new_screens.md)**
   - Detailed testing procedures for specific UI implementations
   - Focus on newly developed screens and components
   - Technical validation steps
   - UI/UX verification

---

## 🎯 Quick Start for Testers

### New to Testing This Application?
1. **Read**: [Comprehensive Testing Guide](./comprehensive_testing_guide.md)
2. **Setup**: Ensure development environment is running
3. **Test**: Follow the step-by-step procedures
4. **Report**: Document any issues found using provided templates

### Testing Checklist
Before starting any testing session:
- [ ] Development server is running (`bin/dev`)
- [ ] Database is migrated and ready
- [ ] User account available for login
- [ ] Browser developer tools available for technical verification

---

## 📱 Testing Scope

### Core Features Covered
- **Authentication** - User registration, login, logout
- **Brand Management** - Creation, editing, validation
- **Content Planning** - Strategy interface, planning tools
- **Reel Creation** - Scene-based and narrative reel forms
- **Analytics** - Data visualization and reporting
- **Settings** - Configuration and API management
- **Component Library** - UI component verification

### Quality Assurance Areas
- **Functionality** - All features work as designed
- **Visual Design** - Consistent theming and responsive layout
- **User Experience** - Intuitive navigation and clear interactions
- **Technical** - No JavaScript errors, proper form validation
- **Mobile** - Touch-friendly and responsive design
- **Performance** - Acceptable load times and responsiveness

---

## 🔧 Testing Environment

### Required Setup
```bash
# Start development environment
bin/dev

# Verify database is ready
rails db:migrate

# Check application is accessible
# Visit: http://localhost:3000
```

### Browser Requirements
- **Primary**: Chrome, Firefox, Safari (latest versions)
- **Mobile**: Mobile Chrome, Mobile Safari
- **Tools**: Browser developer tools enabled

---

## 📊 Testing Process

### Manual Testing Flow
1. **Pre-Testing Setup**
   - Review testing guide
   - Prepare test environment
   - Clear browser cache if needed

2. **Feature Testing**
   - Follow step-by-step procedures
   - Document results for each test case
   - Note any deviations from expected behavior

3. **Technical Verification**
   - Check browser console for errors
   - Verify network requests complete successfully
   - Test responsive design across screen sizes

4. **Issue Reporting**
   - Document issues using provided templates
   - Include screenshots and error details
   - Prioritize issues by severity

---

## 📝 Documentation Updates

### When to Update Testing Documentation
- New features are added to the application
- Existing features change significantly
- Testing procedures need refinement
- New edge cases are discovered

### How to Update
1. Modify relevant testing guide
2. Update this README if new guides are added
3. Ensure testing procedures remain current with application features
4. Test the testing procedures to ensure they work correctly

---

## 🆘 Getting Help

### If Testing Procedures Don't Work
1. Verify development environment setup
2. Check application logs for errors
3. Review recent changes in `/doc/backend/` or `/doc/frontend/`
4. Consult main contributor guide in `CLAUDE.md`

### For Testing Questions
- Review the comprehensive testing guide thoroughly
- Check browser console for detailed error information
- Verify you're following the exact steps as documented
- Ensure test environment matches requirements

---

## ✅ Success Criteria

Manual testing is considered successful when:
- All documented test procedures complete without critical failures
- Visual design is consistent across all tested pages
- User workflows function as expected
- Technical verification shows no blocking issues
- Mobile experience meets usability standards

---

**Testing Documentation Maintained By**: Development Team  
**Last Updated**: August 19, 2025  
**Current Version**: 1.0

---

*For questions about testing procedures or to report issues with the testing documentation itself, refer to the main project contributor guide: [CLAUDE.md](../../CLAUDE.md)*